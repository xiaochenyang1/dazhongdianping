# Stripe 真实支付 SDK 接入设计（EU 沙盒最小闭环）

## 目标

用 Stripe 沙盒（test-mode）替换 EU 区的 `stripe_mock` 支付渠道，打通 PaymentIntent 创建 → 客户端 Stripe Elements 确认 → webhook 验签 → 发券与通知这一条真实链路。CN 区保持 `alipay_mock` 不变，退款仍走本地 DB 审核不出真实资金，本轮不做生产 switchover。

## 范围

### 后端（本轮新写 / 重构）

- 新增 `PaymentChannel` 接口，含 `createIntent` 和 `verifyWebhook` 两方法。
- 新增 `MockPaymentChannel`：从 `TradeService` 迁入现有 mock 逻辑（服务端生成 txnId、内部 SHA-256 签名），行为不变。
- 新增 `StripePaymentChannel`：用 stripe-java 创建 PaymentIntent、验证 `payment_intent.succeeded` webhook。
- 新增 `PaymentChannelResolver`：按 region 与配置路由到正确实现（EU+enabled→Stripe，其余→Mock）。
- `TradeService.pay()` 返回值增加 `clientSecret` 字段。
- `TradeController` 新增 `notifyStripe(HttpServletRequest)` 端点，读原始 body 做 Stripe 签名验签。
- 现有 `POST /orders/{id}/pay/mock-complete` 只在 Mock 通道激活时可用。`TradeService.completeMockPayment()` 先经 Resolver 解析当前 region 的通道，解析结果不是 `MockPaymentChannel` 时抛 `IllegalArgumentException("当前渠道不是模拟支付")`（沿用现有错误文案）。这保证 EU 开启 Stripe 后，mock-complete 无法绕过真实支付把订单刷成已支付。

### 依赖

- `com.stripe:stripe-java:26.12.0`（Java 17 + Spring Boot 3.x 兼容，截至 2026-08 最新稳定版）

### Web（本轮新写）

- 安装 `@stripe/stripe-js`。
- `OrderDetailView.vue`（订单详情页）：如果 `clientSecret` 非空，渲染 Stripe Elements CardElement + 确认按钮；如果为空，保留现有 `mock-complete` 按钮。
- 封装一个 `useStripeCheckout` composable：create Elements、attach、confirm、错误恢复。

### Flutter（本轮新写）

- 安装 `flutter_stripe`。
- 订单详情 Screen：如果 `clientSecret` 非空，调用 `Stripe.instance.presentPaymentSheet()`；如果为空，保留 mock-complete 路径。
- `third_party_config.dart` 新增 `stripePublishableKey`（已预留字段，当前为空）。

### 不做（明确排除）

- 真实退款出账（`refund()` 继续只写本地 DB 审核行）
- 支付宝/微信真实接入
- 部分退款
- Stripe webhook 密钥轮换
- 支付超时自动关单逻辑调整（现有定时关单保持）
- 生产凭证管理（publishable key 仍走 dart-define / env var，secret key 仍走 `application.yml` env var）
- PC Web 社区写操作（仍然是只读，不新增 I'm-feeling-lucky）

## 架构与模块边界

```
backend/src/main/java/.../module/trade/payment/
├── PaymentChannel.java          ← 接口
├── PaymentChannelResolver.java  ← region × config 路由
├── StripePaymentChannel.java    ← 真实 Stripe（stripe-java）
└── MockPaymentChannel.java      ← 现有 mock 逻辑迁入
```

### 接口定义

```java
public interface PaymentChannel {
    PaymentIntentResult createIntent(OrderRow order, PaymentRow payment);
    PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest);
    boolean supports(String region, String channel);
}
```

`PaymentIntentResult` 是 DTO：`{ channel, channelTxn, clientSecret }`。`PaymentNotifyResult` 是 DTO：`{ orderNo, channelTxn, amount, success }`。

`StripePaymentChannel` 注入 `com.stripe.StripeClient`（由 `StripeConfig` 根据 `app.payment.stripe.secret-key` 创建 Bean）。`MockPaymentChannel` 复用 `TradeMapper` + `app.payment.notify-secret`。

### 路由决策表

| Region | stripe.enabled | mock-enabled | 解析结果 |
|---|---|---|---|
| EU | true | - | StripePaymentChannel |
| EU | false | true | MockPaymentChannel(stripe_mock) |
| CN | - | true | MockPaymentChannel(alipay_mock) |
| any | false | false | `requirePaymentChannel()` → 503 |

### 为什么 CN 保持 Mock

本轮只做 Stripe。支付宝需要企业主体资质（营业执照审核），个人开发者通常无法通过。CN 区保持本地 mock 闭环不影响演示，后续加支付宝时作为 `PaymentChannel` 的第三个实现。

## 数据流

### A. 发起支付 — POST /orders/{id}/pay

```
Client → TradeController.pay()
  → TradeService.pay()
    → resolver.resolve(region) → StripePaymentChannel
    → stripeClient.paymentIntents().create(params)
    → mapper.insertPayment(payment)  // channel="stripe", channelTxn="pi_xxx"
  → { paymentId, channel:"stripe", channelTxn:"pi_xxx",
      clientSecret:"pi_xxx_secret_...", orderNo, amount, currency }
```

Stripe PaymentIntent 参数：amount（最小单位 × 100）、currency（小写 `eur`/`gbp`）、`metadata[orderNo]`、`payment_method_types=["card"]`、`capture_method="automatic"`。

`clientSecret` 是 Stripe 返回的 `pi_xxx_secret_xxx` 字符串，直接透传给前端，不做加工。

### B. Webhook — POST /pay/notify/stripe

```
Stripe 服务器 → Controller.notifyStripe(HttpServletRequest)
  → resolver.resolveByChannel("stripe")
  → StripePayChannel.verifyWebhook(request)
    1. payload = request.getInputStream().readAllBytes()
    2. sig = request.getHeader("Stripe-Signature")
    3. event = StripeClient.constructEvent(payload, sig, endpointSecret)
    4. if event.type != "payment_intent.succeeded" → { success: false }
    5. pi = event.data.object as PaymentIntent
    6. → { orderNo: pi.metadata["orderNo"], channelTxn: pi.id, amount: pi.amount/100, success: true }
  → TradeService.notifyInternal(channel, orderNo, channelTxn, amount)
    // 复用现有幂等、发券、通知逻辑，不做新事
  → 200 OK
```

**关键设计决策**：`TradeService.notifyInternal()` 是从现有 `notify(String channel, PaymentNotifyRequest)` 中抽出来的内部方法，只处理已验证为合法的通知。Mock 的 SHA-256 签名步骤移到 `MockPaymentChannel.verifyWebhook()` 内部，`notifyInternal` 不关心签名。

**Controller 变化**：新增 `notifyStripe(HttpServletRequest request)`，注解为 `@PostMapping("/pay/notify/stripe")`，注入 `HttpServletRequest` 获取 raw body。Spring Boot 3.x 的默认 `DispatcherServlet` 不会缓存原始 body，需要 Controller access 在 body 被解析之前拿到（直接读 `getInputStream()` 即可，因为 `@RequestBody` 还没调用）。如果出现消费冲突，添加 `ContentCachingRequestWrapper` filter 专门给 `/pay/notify/**` 路径。

现有 `POST /pay/notify/{channel}` 保留给 Mock：`notify(String channel, @RequestBody PaymentNotifyRequest)` 路径不变，Mock 继续走 JSON 请求体 + SHA-256 比较。

### C. 支付成功到客户端

不走轮询。Webhook 接收 → `notifyInternal` 更新订单 `payStatus=1`、发券 → `NotificationService.create(ORDER_PAID_TYPE)` → WebSocket 推 `order.paid` 到客户端。客户端收到推送后刷新订单状态到"已支付"。

这套站内通知链路（WebSocket + REST 补偿）已经存在且验证通过，Stripe webhook 只是换了一个触发源（以前是 `mock-complete` 内部调用 `notify()`）。

### D. 退款

`POST /orders/{id}/refund` 行为不变：写本地 `refund` 行、标记状态为申请中。商户和管理端审核退款时只改本地状态，不调 `stripe.refunds().create()`。退款出账留到下一轮。

## 配置

```yaml
# application.yml
app:
  payment:
    notify-secret: ${APP_PAYMENT_NOTIFY_SECRET:}
    mock-enabled: ${APP_PAYMENT_MOCK_ENABLED:false}
    stripe:
      enabled: ${APP_PAYMENT_STRIPE_ENABLED:false}
      secret-key: ${APP_PAYMENT_STRIPE_SECRET_KEY:}
      endpoint-secret: ${APP_PAYMENT_STRIPE_ENDPOINT_SECRET:}
      api-base-url: ${APP_PAYMENT_STRIPE_API_BASE_URL:https://api.stripe.com}

# application-local.yml — stripe 块不出现，mock 保持打开
app:
  payment:
    mock-enabled: ${APP_PAYMENT_MOCK_ENABLED:true}
```

`secret-key` 以 `sk_test_` 开头（test-mode），前端永远拿不到。`endpoint-secret` 以 `whsec_` 开头，Stripe Dashboard → Webhooks → Signing secret。

`stripe.enabled` 独立于 `mock-enabled`，两者可同时为 true。本地验收时可先只开 mock 验证基础链路通畅，然后设 `APP_PAYMENT_STRIPE_ENABLED=true` 切到沙盒，不用重启改其他配置。

## 错误处理

每个 Stripe 异常映射到现有统一响应体系，不做新错误码：

| Stripe 异常 | 映射 messageKey | HTTP |
|---|---|---|
| `AuthenticationException`（sk 无效）| `payment.channel_unavailable` | 503 |
| `InvalidRequestException`（金额/币种/参数非法）| 原异常 message | 400 |
| `SignatureVerificationException`（webhook sig 非法）| `payment.invalid_signature` | 400 |
| `CardException`（支付确认失败 — Stripe.js 侧，非服务端）| 由客户端 Stripe Elements 展示，不经过本服务 | - |
| `ApiConnectionException`（网络超时）| `payment.channel_timeout` | 502 |
| 其他 `StripeException` | `payment.channel_unavailable` | 503 |

`PaymentChannelResolver.resolve()` 在 Stripe 未启用且 mock 未启用时抛 `ServiceUnavailableException("支付渠道尚未配置")`，与现有行为一致。

## 前后端契约

### `POST /orders/{id}/pay` 响应新增字段

```
Before: { paymentId, channel, channelTxn, orderNo, amount, currency }
After:  { paymentId, channel, channelTxn, clientSecret, orderNo, amount, currency }
                                       ^^^^^^^^^^^^ 新增字段，mock 时为空字符串 ""
```

`web/src/types/trade.ts` 的 `PaymentIntent` 接口加 `clientSecret?: string`。

### `StripeConfig` Bean

```java
@Configuration
public class StripeConfig {
    @Bean
    @ConditionalOnProperty("app.payment.stripe.enabled")
    public StripeClient stripeClient(
        @Value("${app.payment.stripe.secret-key}") String secretKey,
        @Value("${app.payment.stripe.api-base-url}") String apiBaseUrl
    ) {
        StripeClient client = new StripeClient(secretKey);
        client.setApiBase(apiBaseUrl);
        return client;
    }
}
```

`Stripe.apiKey` 静态全局 setter 方案被否决 — Spring Boot 语境里静态全局会让测试隔离变得困难，且 `StripeClient` 实例更干净。`@ConditionalOnProperty` 确保不配凭证也可以启动（mock 分支可用）。

### Web 端新增依赖

```json
// package.json 新增
"@stripe/stripe-js": "^1.54.0"
```

Stripe Elements 在订单详情页按需挂载（只有 `clientSecret` 非空时才 loadStripe + create elements）。composable 结构：

```typescript
// composables/useStripeCheckout.ts
interface UseStripeCheckout {
  elements: Ref<StripeElements | null>
  error: Ref<string>
  processing: Ref<boolean>
  mount(cardElement: HTMLElement, clientSecret: string): Promise<void>
  confirm(): Promise<boolean>  // true = payment confirmed by Stripe, result by webhook
  unmount(): void
}
```

Publishable key 通过 `VITE_STRIPE_PUBLISHABLE_KEY` 环境变量注入，不需要从后端取。

### Flutter 端新增依赖

```yaml
# pubspec.yaml 新增
flutter_stripe: ^11.4.0
```

`Stripe.publishableKey` 由 `ThirdPartyConfig.stripePublishableKey` 初始化（已预留字段，通过 `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...` 传入）。

启动时在 `main.dart` 调用 `Stripe.instance.applySettings()` 注入 publishable key。

Flutter 端支付流程：

1. 调用 `POST /orders/{id}/pay`，拿到 `clientSecret`
2. `await Stripe.instance.initPaymentSheet(paymentSheetParameters: PaymentSheetParameters(clientSecret: clientSecret, ...))`
3. `await Stripe.instance.presentPaymentSheet()`
4. 成功 → 服务端 webhook 更新订单 → WebSocket 推通知 → 页面跳转已支付订单详情

`flutter_stripe` 的 PaymentSheet 自动处理 SCA/3DS2、卡号输入、错误展示，不需要 Flutter 手写卡号表单。

## 改动文件清单

### 后端（新建 + 修改）

| 文件 | 动作 |
|---|---|
| `module/trade/payment/PaymentChannel.java` | 新建 |
| `module/trade/payment/PaymentChannelResolver.java` | 新建 |
| `module/trade/payment/StripePaymentChannel.java` | 新建 |
| `module/trade/payment/MockPaymentChannel.java` | 新建 |
| `config/StripeConfig.java` | 新建 |
| `module/trade/service/TradeService.java` | 改 — 注入 Resolver，`pay()` 加 `clientSecret`，抽出 `notifyInternal` |
| `module/trade/controller/TradeController.java` | 改 — 新增 `notifyStripe(HttpServletRequest)` |
| `src/main/resources/application.yml` | 改 — 新增 `app.payment.stripe.*` |
| `src/test/.../trade/service/TradeServiceFailClosedTest.java` | 改 — 适配 Resolver 注入 |
| 新增聚焦测试 | 新建 — `StripePaymentChannelTest`、`PaymentChannelResolverTest` |

### Web

| 文件 | 动作 |
|---|---|
| `package.json` | 改 — `@stripe/stripe-js` |
| `src/types/trade.ts` | 改 — `PaymentIntent.clientSecret` |
| `src/composables/useStripeCheckout.ts` | 新建 |
| `src/views/OrderDetailView.vue` | 改 — 条件渲染 Stripe Elements 或 mock-complete 按钮 |
| `src/views/OrderDetailView.test.ts` | 改 — 覆盖两条支付路径 |

### Flutter

| 文件 | 动作 |
|---|---|
| `pubspec.yaml` | 改 — `flutter_stripe` |
| `lib/core/third_party_config.dart` | 改 — `stripePublishableKey` 已预留，确认 wiring |
| `lib/main.dart`（或 bootstrap 入口）| 改 — `Stripe.instance.applySettings()` |
| `lib/features/trade/order_detail_screen.dart` | 改 — `clientSecret` 非空走 PaymentSheet |

## 验证

- 后端 `StripePaymentChannel` 单元测试用 mock `StripeClient`，覆盖正常创建、异常映射、webhook 验签成功/失败。
- `PaymentChannelResolver` 单元测试覆盖四行决策表。
- `TradeService` 聚焦测试验证 `notifyInternal` 与 Resolver 的协作。
- Web `useStripeCheckout` 单元测试覆盖 mount/confirm/unmount 状态转换。
- 集成验收：后端启动 + webhook endpoint 用 Stripe CLI `stripe trigger payment_intent.succeeded` 发测试事件，确认 `notifyInternal` 收到正确的 orderNo 和 amount。
- `flutter analyze` 零问题，`flutter test` 全量通过。

## 不涵盖

- 真实 Stripe 凭证（`sk_test_*`、`whsec_*`、`pk_test_*`）— 由开发者从 Stripe Dashboard 获取并注入环境变量
- Stripe Dashboard 的 Webhook endpoint URL 注册 — 本地开发用 `stripe listen --forward-to localhost:8080/api/c/v1/pay/notify/stripe`
- iOS/Android 原生 Stripe SDK 初始化配置 — Flutter 端由 `flutter_stripe` 管理
- 生产 switchover（`sk_live_*`、`whsec_*` prod secret、card acquiring 合规）
