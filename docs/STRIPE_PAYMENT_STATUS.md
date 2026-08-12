# Stripe 真实支付实现状态

**更新时间**: 2026-08-12  
**状态**: ✅ 代码实现已完成，可进行端到端测试

## 概览

Stripe test-mode 支付集成的代码实现已完成，所有单元测试通过。后端、Web 和 Flutter 客户端均已实现相关功能。

## 已完成的工作

### 后端 (Java)
✅ **核心实现**
- `PaymentChannel` 接口及 DTOs (`PaymentIntentResult`, `PaymentNotifyResult`)
- `MockPaymentChannel` - 迁移现有 mock 逻辑
- `StripePaymentChannel` - Stripe PaymentIntent 创建 + webhook 验签
- `PaymentChannelResolver` - 按 region + config 路由渠道
- `StripeConfig` - 条件装配的 `StripeClient` Bean
- `TradeService` - 集成 resolver，支持 `clientSecret`
- `TradeController` - webhook endpoints

✅ **依赖管理**
- `stripe-java` 26.12.0 已添加到 `pom.xml`

✅ **测试覆盖**
- `MockPaymentChannelTest` - 4 tests ✓
- `StripePaymentChannelTest` - 6 tests ✓
- `PaymentChannelResolverTest` - 6 tests ✓
- 所有 payment 相关测试通过 (16/16)
- 全后端测试套件通过 (435 tests)

✅ **配置**
```yaml
app:
  payment:
    notify-secret: ${APP_PAYMENT_NOTIFY_SECRET:}
    mock-enabled: ${APP_PAYMENT_MOCK_ENABLED:false}
    stripe:
      enabled: ${APP_PAYMENT_STRIPE_ENABLED:false}
      secret-key: ${APP_PAYMENT_STRIPE_SECRET_KEY:}
      endpoint-secret: ${APP_PAYMENT_STRIPE_ENDPOINT_SECRET:}
```

### Web 前端 (Vue + TypeScript)
✅ **实现文件**
- `useStripeCheckout.ts` - Stripe Elements 生命周期管理
- `OrderDetailView.vue` - 支持 `clientSecret` 分支渲染
- `trade.ts` 类型定义包含 `clientSecret` 字段

✅ **依赖管理**
- `@stripe/stripe-js` 1.54.2 已添加

✅ **测试覆盖**
- `OrderDetailView.test.ts` - 5 tests ✓
  - 包含 clientSecret 存在/不存在场景
  - Stripe card form 显示逻辑
  - Mock payment fallback

### Flutter 客户端
✅ **实现**
- `order_detail_screen.dart` - 集成 `flutter_stripe` PaymentSheet
- 支持 `clientSecret` → `initPaymentSheet` → `presentPaymentSheet` 流程

✅ **依赖管理**
- `flutter_stripe` ^11.4.0 已添加

✅ **测试状态**
- Flutter 测试套件全通过 (569 tests)

## 剩余工作

### 1. 端到端测试 (最高优先级)
**Web 端**
- [ ] 本地启动后端 + Stripe CLI webhook forwarding
- [ ] 创建测试订单 → 调用 pay → 确认 clientSecret 返回
- [ ] 填写 Stripe test card (4242 4242 4242 4242)
- [ ] 确认支付成功 → webhook 触发 → 券码发放

**Flutter 端**
- [ ] 同上流程，使用 PaymentSheet UI

### 2. Stripe CLI Webhook 本地测试
```bash
# 安装 Stripe CLI
brew install stripe/stripe-cli/stripe

# 登录
stripe login

# 转发 webhook 到本地
stripe listen --forward-to http://localhost:8080/api/c/v1/pay/notify/stripe

# 获取 webhook signing secret (ws_test_xxx)
# 配置到 APP_PAYMENT_STRIPE_ENDPOINT_SECRET
```

### 3. 文档完善
- [ ] 添加 `.env.example` 示例配置
- [ ] 更新 README - Stripe test mode 配置步骤
- [ ] 在 `/docs` 中添加 Stripe 集成指南

### 4. 计划文档同步
- [ ] 更新 `docs/superpowers/plans/2026-08-07-real-stripe-payment.md` 的 checkbox 状态

## 配置要求

### 环境变量
```bash
# Stripe test mode keys (从 https://dashboard.stripe.com/test/apikeys 获取)
APP_PAYMENT_STRIPE_ENABLED=true
APP_PAYMENT_STRIPE_SECRET_KEY=sk_test_xxxxx
APP_PAYMENT_STRIPE_ENDPOINT_SECRET=whsec_xxxxx

# Web 前端
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx

# Flutter (在 ThirdPartyConfig 中传递)
stripePublishableKey: pk_test_xxxxx
```

### Stripe Test Cards
- 成功: `4242 4242 4242 4242`
- 需要 3DS: `4000 0025 0000 3155`
- 失败: `4000 0000 0000 9995`

## 架构说明

### 支付渠道路由
```
TradeService.pay()
    ↓
PaymentChannelResolver.resolve(region)
    ↓
├─ CN region → MockPaymentChannel (alipay_mock)
└─ EU region → StripePaymentChannel (stripe) or MockPaymentChannel (stripe_mock)
```

### Webhook 验签流程
```
POST /api/c/v1/pay/notify/stripe
    ↓
StripePaymentChannel.verifyWebhook(HttpServletRequest)
    ↓ (读取原始 body + Stripe-Signature header)
    ↓
Webhook.constructEvent() → 验签
    ↓
TradeService.notifyInternal() → 发券 + 通知
```

## 测试命令速查

```bash
# 后端测试
cd backend && ./mvnw test

# Payment 相关测试
./mvnw test -Dtest=MockPaymentChannelTest,StripePaymentChannelTest,PaymentChannelResolverTest

# Web 测试
cd web && npm test -- OrderDetailView

# Flutter 测试
cd app && flutter test

# Flutter 静态分析
cd app && flutter analyze
```

## 参考文档
- 设计文档: `docs/superpowers/specs/2026-08-07-real-stripe-payment-design.md` (297 lines)
- 实施计划: `docs/superpowers/plans/2026-08-07-real-stripe-payment.md` (91 checkboxes)
- Stripe API 文档: https://stripe.com/docs/api
- Stripe Test Mode: https://stripe.com/docs/testing
