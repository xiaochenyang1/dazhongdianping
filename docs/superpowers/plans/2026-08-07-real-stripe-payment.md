# Stripe 真实支付接入实施计划（EU 沙盒）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用 Stripe test mode 替换 EU 区的 `stripe_mock`，打通 PaymentIntent → 客户端确认 → webhook 验签 → 发券通知的真实链路，CN 区保持 `alipay_mock` 不变。

**Architecture:** 在 `TradeService` 与具体支付渠道之间插入 `PaymentChannel` 接口。现有 mock 逻辑迁入 `MockPaymentChannel`，Stripe 走 `StripePaymentChannel`，`PaymentChannelResolver` 按 region + 配置路由。`TradeService.notify()` 拆成"验签"（渠道负责）与 `notifyInternal()`（发券/通知，渠道无关）两段，因为 mock 验签的是已解析的 JSON 字段，Stripe 验签的是原始 body 字节，两者无法共用一条路径。

**Tech Stack:** Java 17 / Spring Boot 3.3.5 / MyBatis / JUnit 5 + Mockito / `com.stripe:stripe-java` / Vue 3 + TypeScript + Vitest / `@stripe/stripe-js` / Flutter + `flutter_stripe`

## Global Constraints

- 后端包根：`com.tuowei.dazhongdianping`，支付新包 `module.trade.payment`
- stripe-java 版本：`26.12.0`（Java 17 + Spring Boot 3.x 兼容）
- `@stripe/stripe-js` 版本：`^1.54.0`；`flutter_stripe` 版本：`^11.4.0`
- **Stripe 渠道名固定为 `stripe`（不带 `_mock` 后缀）** —— `TradeService.completeMockPayment()` 现有守卫是 `channel.endsWith("_mock")`，命名对了这条守卫就自动挡住 Stripe 订单，无需新增判断
- **`pay()` 返回值用 `Map.of()`，null 会抛 NPE** —— mock 的 `clientSecret` 必须是 `""`，绝不可为 null
- 所有新配置默认 fail-closed：`app.payment.stripe.enabled` 默认 `false`，不配凭证服务必须能正常启动
- 异常沿用 `common.api` 现有类型，不新增异常类
- 现有代码是高度压缩的单行风格（见 `TradeService.java`）；**新建文件用正常多行格式**，只在修改现有单行时保持其风格
- 后端测试命令：`cd backend && ./mvnw -q test -Dtest=<TestClass>`
- Web 测试命令：`cd web && npm test`
- Flutter 检查：`cd app && flutter analyze && flutter test`
- 不做真实退款出账、不做支付宝、不做生产 switchover

## File Structure

| 文件 | 责任 |
|---|---|
| `payment/PaymentIntentResult.java` | 发起支付的返回 DTO（record） |
| `payment/PaymentNotifyResult.java` | webhook 验签后的结果 DTO（record） |
| `payment/PaymentChannel.java` | 渠道接口，2 个方法 + `supports()` |
| `payment/MockPaymentChannel.java` | 现有 mock 逻辑（自生成 txn + SHA-256 验签） |
| `payment/StripePaymentChannel.java` | Stripe PaymentIntent 创建 + 原始 body 验签 |
| `payment/PaymentChannelResolver.java` | region × config → 渠道实现 |
| `config/StripeConfig.java` | `StripeClient` Bean，条件装配 |
| `trade/service/TradeService.java` | 改：注入 resolver，`pay()` 加 `clientSecret`，抽 `notifyInternal()` |
| `trade/controller/TradeController.java` | 改：新增 `notifyStripe(HttpServletRequest)` |
| `web/src/composables/useStripeCheckout.ts` | Stripe Elements 生命周期封装 |
| `web/src/views/OrderDetailView.vue` | 改：按 `clientSecret` 分支渲染 |
| `app/lib/features/trade/order_detail_screen.dart` | 改：按 `clientSecret` 走 PaymentSheet |

---

### Task 1: DTOs and PaymentChannel Interface

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentIntentResult.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentNotifyResult.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentChannel.java`

**Interfaces:**
- Consumes: 现有 `OrderRow` / `PaymentRow` from `trade.model`
- Produces: `PaymentChannel` 接口，2 DTO records，供 Task 2/3 实现

- [x] **Step 1: Write PaymentIntentResult record**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

public record PaymentIntentResult(
    String channel,
    String channelTxn,
    String clientSecret
) {}
```

- [x] **Step 2: Write PaymentNotifyResult record**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import java.math.BigDecimal;

public record PaymentNotifyResult(
    String orderNo,
    String channelTxn,
    BigDecimal amount,
    boolean success
) {}
```

- [x] **Step 3: Write PaymentChannel interface**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;

public interface PaymentChannel {
    PaymentIntentResult createIntent(OrderRow order, PaymentRow payment);
    PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest);
    boolean supports(String region, String channel);
}
```

- [x] **Step 4: Verify compilation**

Run: `cd backend && ./mvnw clean compile`
Expected: SUCCESS

- [x] **Step 5: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/
git commit -m "feat(payment): add PaymentChannel interface and DTOs

Introduce PaymentIntentResult (channel + txn + clientSecret),
PaymentNotifyResult (orderNo + amount + success), and the
PaymentChannel interface with createIntent / verifyWebhook.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: MockPaymentChannel Implementation

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/MockPaymentChannel.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/MockPaymentChannelTest.java`

**Interfaces:**
- Consumes: `PaymentChannel` interface from Task 1, `TradeMapper` for `selectPaymentByTxn`
- Produces: `MockPaymentChannel` 实现类，SHA-256 验签逻辑从 TradeService 迁入

- [x] **Step 1: Write failing test for createIntent**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class MockPaymentChannelTest {

    private final TradeMapper mapper = mock(TradeMapper.class);
    private final String secret = "test-secret-001";
    private final MockPaymentChannel channel = new MockPaymentChannel(mapper, secret);

    @Test
    void shouldCreateIntentWithGeneratedTxnAndEmptyClientSecret() {
        OrderRow order = new OrderRow();
        order.setRegion("CN");
        order.setOrderNo("OD12345");
        order.setAmount(new BigDecimal("100.00"));

        PaymentRow payment = new PaymentRow();

        PaymentIntentResult result = channel.createIntent(order, payment);

        assertEquals("alipay_mock", result.channel());
        assertTrue(result.channelTxn().startsWith("TX"));
        assertEquals(24, result.channelTxn().length());
        assertEquals("", result.clientSecret());
    }

    @Test
    void shouldUseStripeMockChannelForEU() {
        OrderRow order = new OrderRow();
        order.setRegion("EU");

        PaymentRow payment = new PaymentRow();

        PaymentIntentResult result = channel.createIntent(order, payment);

        assertEquals("stripe_mock", result.channel());
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=MockPaymentChannelTest`
Expected: FAIL with "MockPaymentChannel does not exist"

- [x] **Step 3: Write minimal MockPaymentChannel**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.request.PaymentNotifyRequest;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class MockPaymentChannel implements PaymentChannel {

    private final TradeMapper mapper;
    private final String secret;

    public MockPaymentChannel(TradeMapper mapper, String secret) {
        this.mapper = mapper;
        this.secret = secret;
    }

    @Override
    public PaymentIntentResult createIntent(OrderRow order, PaymentRow payment) {
        String channel = "CN".equals(order.getRegion()) ? "alipay_mock" : "stripe_mock";
        String txn = "TX" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
        return new PaymentIntentResult(channel, txn, "");
    }

    @Override
    public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
        // Parse JSON body as PaymentNotifyRequest, verify SHA-256 signature
        // Placeholder — will implement in next step
        throw new UnsupportedOperationException("verifyWebhook not yet implemented");
    }

    @Override
    public boolean supports(String region, String channel) {
        return channel != null && channel.endsWith("_mock");
    }

    private String sign(String orderNo, String txn, String status, BigDecimal amount) {
        try {
            String raw = orderNo + "|" + txn + "|" + status + "|"
                    + amount.setScale(2).toPlainString() + "|" + secret;
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8))
            );
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
```

- [x] **Step 4: Run test to verify createIntent passes**

Run: `cd backend && ./mvnw -q test -Dtest=MockPaymentChannelTest`
Expected: 2 tests PASS

- [x] **Step 5: Write test for verifyWebhook**

Add to `MockPaymentChannelTest.java`:

```java
@Test
void shouldVerifyWebhookWithCorrectSignature() throws Exception {
    String orderNo = "OD12345";
    String txn = "TX123456789012345678901234";
    BigDecimal amount = new BigDecimal("100.00");
    String correctSig = signForTest(orderNo, txn, "SUCCESS", amount);

    String jsonBody = String.format(
        "{\"orderNo\":\"%s\",\"channelTxn\":\"%s\",\"status\":\"SUCCESS\",\"amount\":%s,\"signature\":\"%s\"}",
        orderNo, txn, amount.toPlainString(), correctSig
    );

    HttpServletRequest request = mockRequest(jsonBody);

    PaymentRow payment = new PaymentRow();
    payment.setOrderNo(orderNo);
    payment.setChannelTxn(txn);
    when(mapper.selectPaymentByTxn("alipay_mock", txn)).thenReturn(payment);

    PaymentNotifyResult result = channel.verifyWebhook(request);

    assertTrue(result.success());
    assertEquals(orderNo, result.orderNo());
    assertEquals(amount, result.amount());
}

@Test
void shouldRejectWebhookWithInvalidSignature() throws Exception {
    String jsonBody = "{\"orderNo\":\"OD12345\",\"channelTxn\":\"TX123\",\"status\":\"SUCCESS\",\"amount\":100.00,\"signature\":\"badhex\"}";
    HttpServletRequest request = mockRequest(jsonBody);

    assertThrows(IllegalArgumentException.class, () -> channel.verifyWebhook(request));
}

private String signForTest(String orderNo, String txn, String status, BigDecimal amount) {
    try {
        String raw = orderNo + "|" + txn + "|" + status + "|" + amount.setScale(2).toPlainString() + "|test-secret-001";
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
}

private HttpServletRequest mockRequest(String body) throws IOException {
    HttpServletRequest req = mock(HttpServletRequest.class);
    when(req.getInputStream()).thenReturn(new jakarta.servlet.ServletInputStream() {
        private final java.io.ByteArrayInputStream bais = new java.io.ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8));
        @Override public int read() { return bais.read(); }
        @Override public boolean isFinished() { return bais.available() == 0; }
        @Override public boolean isReady() { return true; }
        @Override public void setReadListener(jakarta.servlet.ReadListener listener) {}
    });
    return req;
}
```

- [x] **Step 6: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=MockPaymentChannelTest`
Expected: FAIL with "verifyWebhook not yet implemented"

- [x] **Step 7: Implement verifyWebhook**

Replace the `verifyWebhook` method in `MockPaymentChannel.java`:

```java
@Override
public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
    try {
        byte[] body = rawRequest.getInputStream().readAllBytes();
        PaymentNotifyRequest req = objectMapper.readValue(body, PaymentNotifyRequest.class);

        if (!sign(req.orderNo(), req.channelTxn(), req.status(), req.amount())
                .equalsIgnoreCase(req.signature())) {
            throw new IllegalArgumentException("支付回调签名非法");
        }

        if (!"SUCCESS".equalsIgnoreCase(req.status())) {
            throw new IllegalArgumentException("支付未成功");
        }

        return new PaymentNotifyResult(req.orderNo(), req.channelTxn(), req.amount(), true);
    } catch (IOException e) {
        throw new IllegalStateException("读取支付回调请求体失败", e);
    }
}
```

`ObjectMapper` 由 Spring Boot Web 自动装配，构造器注入即可。相应地 Step 3 的构造器改为三参数：

```java
private final TradeMapper mapper;
private final String secret;
private final ObjectMapper objectMapper;

public MockPaymentChannel(
        TradeMapper mapper,
        @Value("${app.payment.notify-secret}") String secret,
        ObjectMapper objectMapper) {
    this.mapper = mapper;
    this.secret = secret;
    this.objectMapper = objectMapper;
}
```

Step 1 的测试构造器同步改为 `new MockPaymentChannel(mapper, secret, new ObjectMapper())`。需要 import `com.fasterxml.jackson.databind.ObjectMapper` 和 `org.springframework.beans.factory.annotation.Value`。

- [x] **Step 8: Run tests to verify all pass**

Run: `cd backend && ./mvnw -q test -Dtest=MockPaymentChannelTest`
Expected: 4 tests PASS

- [x] **Step 9: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/MockPaymentChannel.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/MockPaymentChannelTest.java
git commit -m "feat(payment): implement MockPaymentChannel

Migrate existing mock logic: self-generated txnId, alipay_mock for CN /
stripe_mock for EU, SHA-256 signature verification against parsed JSON
request body. Behavior identical to the current TradeService mock path.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: StripeConfig and Stripe Dependency

**Files:**
- Modify: `backend/pom.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/config/StripeConfig.java`
- Modify: `backend/src/main/resources/application.yml`

**Interfaces:**
- Produces: `StripeClient` Bean（仅当 `app.payment.stripe.enabled=true`），供 Task 4 注入

- [x] **Step 1: Add stripe-java dependency**

在 `backend/pom.xml` 的 `<dependencies>` 中加入：

```xml
<dependency>
    <groupId>com.stripe</groupId>
    <artifactId>stripe-java</artifactId>
    <version>26.12.0</version>
</dependency>
```

- [x] **Step 2: Verify dependency resolves**

Run: `cd backend && ./mvnw -q dependency:resolve -Dsilent=true`
Expected: SUCCESS，无 dependency resolution 报错

- [x] **Step 3: Add stripe config block to application.yml**

在 `application.yml` 的 `app.payment` 下新增（保持现有 `notify-secret` 与 `mock-enabled` 不动）：

```yaml
app:
  payment:
    stripe:
      enabled: ${APP_PAYMENT_STRIPE_ENABLED:false}
      secret-key: ${APP_PAYMENT_STRIPE_SECRET_KEY:}
      endpoint-secret: ${APP_PAYMENT_STRIPE_ENDPOINT_SECRET:}
```

- [x] **Step 4: Write StripeConfig**

```java
package com.tuowei.dazhongdianping.config;

import com.stripe.StripeClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StripeConfig {

    @Bean
    @ConditionalOnProperty(name = "app.payment.stripe.enabled", havingValue = "true")
    public StripeClient stripeClient(
            @Value("${app.payment.stripe.secret-key}") String secretKey) {
        if (secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException(
                "app.payment.stripe.enabled=true 但未配置 app.payment.stripe.secret-key");
        }
        return new StripeClient(secretKey);
    }
}
```

- [x] **Step 5: Verify app still starts without Stripe credentials**

Run: `cd backend && ./mvnw -q test -Dtest=TradeServiceFailClosedTest`
Expected: PASS —— 证明不配 Stripe 凭证时上下文仍可装配

- [x] **Step 6: Commit**

```bash
git add backend/pom.xml backend/src/main/java/com/tuowei/dazhongdianping/config/StripeConfig.java backend/src/main/resources/application.yml
git commit -m "feat(payment): add stripe-java dependency and conditional client bean

StripeClient is only created when app.payment.stripe.enabled=true, so the
service starts normally without any Stripe credentials. Fails fast with a
clear message if enabled but the secret key is missing.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: StripePaymentChannel — createIntent

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannel.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannelTest.java`

**Interfaces:**
- Consumes: `PaymentChannel` (Task 1), `StripeClient` (Task 3)
- Produces: `StripePaymentChannel` with working `createIntent`; `verifyWebhook` lands in Task 5

- [x] **Step 1: Write failing test for createIntent**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.stripe.StripeClient;
import com.stripe.exception.AuthenticationException;
import com.stripe.model.PaymentIntent;
import com.stripe.service.PaymentIntentService;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class StripePaymentChannelTest {

    private final StripeClient stripeClient = mock(StripeClient.class);
    private final PaymentIntentService intentService = mock(PaymentIntentService.class);
    private final StripePaymentChannel channel =
        new StripePaymentChannel(stripeClient, "whsec_test_secret");

    private OrderRow order() {
        OrderRow o = new OrderRow();
        o.setRegion("EU");
        o.setOrderNo("OD12345");
        o.setAmount(new BigDecimal("100.00"));
        o.setCurrency("EUR");
        return o;
    }

    @Test
    void shouldCreateIntentAndReturnClientSecret() throws Exception {
        PaymentIntent stripeIntent = mock(PaymentIntent.class);
        when(stripeIntent.getId()).thenReturn("pi_test_123");
        when(stripeIntent.getClientSecret()).thenReturn("pi_test_123_secret_abc");
        when(stripeClient.paymentIntents()).thenReturn(intentService);
        when(intentService.create(any(com.stripe.param.PaymentIntentCreateParams.class)))
            .thenReturn(stripeIntent);

        PaymentIntentResult result = channel.createIntent(order(), new PaymentRow());

        assertEquals("stripe", result.channel());
        assertEquals("pi_test_123", result.channelTxn());
        assertEquals("pi_test_123_secret_abc", result.clientSecret());
    }

    @Test
    void shouldMapAuthenticationExceptionToServiceUnavailable() throws Exception {
        when(stripeClient.paymentIntents()).thenReturn(intentService);
        when(intentService.create(any(com.stripe.param.PaymentIntentCreateParams.class)))
            .thenThrow(new AuthenticationException("bad key", null, null, 401));

        assertThrows(ServiceUnavailableException.class,
            () -> channel.createIntent(order(), new PaymentRow()));
    }

    @Test
    void shouldSupportOnlyStripeChannel() {
        assertTrue(channel.supports("EU", "stripe"));
        assertFalse(channel.supports("EU", "stripe_mock"));
        assertFalse(channel.supports("CN", "alipay_mock"));
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=StripePaymentChannelTest`
Expected: FAIL with "StripePaymentChannel does not exist"

- [x] **Step 3: Implement StripePaymentChannel with createIntent**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import com.stripe.StripeClient;
import com.stripe.exception.ApiConnectionException;
import com.stripe.exception.AuthenticationException;
import com.stripe.exception.InvalidRequestException;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnBean(StripeClient.class)
public class StripePaymentChannel implements PaymentChannel {

    public static final String CHANNEL = "stripe";

    private final StripeClient stripeClient;
    private final String endpointSecret;

    public StripePaymentChannel(
            StripeClient stripeClient,
            @Value("${app.payment.stripe.endpoint-secret:}") String endpointSecret) {
        this.stripeClient = stripeClient;
        this.endpointSecret = endpointSecret;
    }

    @Override
    public PaymentIntentResult createIntent(OrderRow order, PaymentRow payment) {
        PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                .setAmount(toMinorUnits(order.getAmount()))
                .setCurrency(order.getCurrency().toLowerCase())
                .putMetadata("orderNo", order.getOrderNo())
                .addPaymentMethodType("card")
                .setCaptureMethod(PaymentIntentCreateParams.CaptureMethod.AUTOMATIC)
                .build();
        try {
            PaymentIntent intent = stripeClient.paymentIntents().create(params);
            return new PaymentIntentResult(CHANNEL, intent.getId(), intent.getClientSecret());
        } catch (StripeException e) {
            throw translate(e);
        }
    }

    @Override
    public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
        throw new UnsupportedOperationException("verifyWebhook implemented in Task 5");
    }

    @Override
    public boolean supports(String region, String channel) {
        return CHANNEL.equals(channel);
    }

    private long toMinorUnits(BigDecimal amount) {
        return amount.movePointRight(2).longValueExact();
    }

    private RuntimeException translate(StripeException e) {
        if (e instanceof InvalidRequestException) {
            return new IllegalArgumentException(e.getMessage());
        }
        if (e instanceof AuthenticationException || e instanceof ApiConnectionException) {
            return new ServiceUnavailableException("支付渠道暂时不可用");
        }
        return new ServiceUnavailableException("支付渠道暂时不可用");
    }
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `cd backend && ./mvnw -q test -Dtest=StripePaymentChannelTest`
Expected: 3 tests PASS

- [x] **Step 5: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannel.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannelTest.java
git commit -m "feat(payment): implement Stripe createIntent

Create a real PaymentIntent with orderNo in metadata and return its
client_secret. Amounts convert to minor units via movePointRight(2) with
longValueExact so a bad scale fails loudly rather than silently rounding.
Stripe exceptions map onto the existing exception types.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: StripePaymentChannel — verifyWebhook (raw body signature)

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannel.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannelTest.java`

**Interfaces:**
- Consumes: `StripePaymentChannel.createIntent` from Task 4
- Produces: working `verifyWebhook` returning `PaymentNotifyResult`

**为什么这一步单独成任务：** Stripe 验签对的是**原始 body 字节**，不是解析后的字段。必须在任何 `@RequestBody` 解析之前读 `getInputStream()`，否则 servlet 输入流已被消费、签名必然失败。这是整个接入最容易出错的一环。

- [x] **Step 1: Write failing test for webhook signature verification**

在 `StripePaymentChannelTest.java` 追加。用 Stripe 官方的 `Webhook.Signature` 算法自造合法签名头，避免依赖真实网络：

```java
@Test
void shouldVerifySucceededWebhookAndExtractOrderNo() throws Exception {
    String payload = "{\"id\":\"evt_1\",\"object\":\"event\",\"type\":\"payment_intent.succeeded\","
            + "\"api_version\":\"2024-06-20\",\"data\":{\"object\":{\"id\":\"pi_test_123\","
            + "\"object\":\"payment_intent\",\"amount\":10000,\"currency\":\"eur\","
            + "\"metadata\":{\"orderNo\":\"OD12345\"}}}}";
    String sigHeader = testSignature(payload, "whsec_test_secret");

    HttpServletRequest req = mockRequest(payload, sigHeader);

    PaymentNotifyResult result = channel.verifyWebhook(req);

    assertTrue(result.success());
    assertEquals("OD12345", result.orderNo());
    assertEquals("pi_test_123", result.channelTxn());
    assertEquals(new BigDecimal("100.00"), result.amount());
}

@Test
void shouldRejectWebhookWithTamperedSignature() throws Exception {
    String payload = "{\"id\":\"evt_1\",\"type\":\"payment_intent.succeeded\"}";
    HttpServletRequest req = mockRequest(payload, "t=1,v1=deadbeef");

    assertThrows(IllegalArgumentException.class, () -> channel.verifyWebhook(req));
}

@Test
void shouldIgnoreNonSucceededEventTypes() throws Exception {
    String payload = "{\"id\":\"evt_2\",\"object\":\"event\",\"type\":\"payment_intent.created\","
            + "\"api_version\":\"2024-06-20\",\"data\":{\"object\":{\"id\":\"pi_test_9\","
            + "\"object\":\"payment_intent\",\"amount\":10000,\"currency\":\"eur\","
            + "\"metadata\":{\"orderNo\":\"OD999\"}}}}";
    String sigHeader = testSignature(payload, "whsec_test_secret");

    PaymentNotifyResult result = channel.verifyWebhook(mockRequest(payload, sigHeader));

    assertFalse(result.success());
}

/** Build a valid Stripe-Signature header the same way Stripe does. */
private String testSignature(String payload, String secret) throws Exception {
    long timestamp = 1735689600L;
    String signedPayload = timestamp + "." + payload;
    javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
    mac.init(new javax.crypto.spec.SecretKeySpec(
        secret.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256"));
    String v1 = java.util.HexFormat.of().formatHex(
        mac.doFinal(signedPayload.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    return "t=" + timestamp + ",v1=" + v1;
}

private HttpServletRequest mockRequest(String body, String sigHeader) throws java.io.IOException {
    HttpServletRequest req = mock(HttpServletRequest.class);
    when(req.getHeader("Stripe-Signature")).thenReturn(sigHeader);
    when(req.getInputStream()).thenReturn(new jakarta.servlet.ServletInputStream() {
        private final java.io.ByteArrayInputStream bais =
            new java.io.ByteArrayInputStream(body.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        @Override public int read() { return bais.read(); }
        @Override public boolean isFinished() { return bais.available() == 0; }
        @Override public boolean isReady() { return true; }
        @Override public void setReadListener(jakarta.servlet.ReadListener listener) {}
    });
    return req;
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=StripePaymentChannelTest`
Expected: FAIL with "verifyWebhook implemented in Task 5"

- [x] **Step 3: Implement verifyWebhook**

替换 `StripePaymentChannel.verifyWebhook`，并加入所需 import（`com.stripe.model.Event`、`com.stripe.net.Webhook`、`com.stripe.exception.SignatureVerificationException`、`java.io.IOException`、`java.nio.charset.StandardCharsets`、`java.util.Optional`）：

```java
private static final String SUCCEEDED_EVENT = "payment_intent.succeeded";
private static final long TOLERANCE_SECONDS = 300L;

@Override
public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
    String payload;
    try {
        payload = new String(rawRequest.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
    } catch (IOException e) {
        throw new IllegalStateException("读取 Stripe 回调请求体失败", e);
    }

    String sigHeader = rawRequest.getHeader("Stripe-Signature");
    Event event;
    try {
        event = Webhook.constructEvent(payload, sigHeader, endpointSecret, TOLERANCE_SECONDS);
    } catch (SignatureVerificationException e) {
        throw new IllegalArgumentException("Stripe 回调签名非法");
    }

    if (!SUCCEEDED_EVENT.equals(event.getType())) {
        return new PaymentNotifyResult(null, null, null, false);
    }

    PaymentIntent intent = (PaymentIntent) event.getDataObjectDeserializer()
            .getObject()
            .orElseThrow(() -> new IllegalStateException("Stripe 回调事件缺少 PaymentIntent 对象"));

    String orderNo = intent.getMetadata() == null ? null : intent.getMetadata().get("orderNo");
    if (orderNo == null || orderNo.isBlank()) {
        throw new IllegalArgumentException("Stripe 回调缺少 orderNo metadata");
    }

    BigDecimal amount = BigDecimal.valueOf(intent.getAmount()).movePointLeft(2).setScale(2);
    return new PaymentNotifyResult(orderNo, intent.getId(), amount, true);
}
```

- [x] **Step 4: Run tests to verify all pass**

Run: `cd backend && ./mvnw -q test -Dtest=StripePaymentChannelTest`
Expected: 6 tests PASS

如果 `getDataObjectDeserializer().getObject()` 返回空 Optional，说明测试 payload 的 `api_version` 与 stripe-java 26.12.0 期望的版本不匹配。把 payload 里的 `api_version` 改为该库 `Stripe.API_VERSION` 常量的值即可。

- [x] **Step 5: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannel.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/StripePaymentChannelTest.java
git commit -m "feat(payment): verify Stripe webhooks against the raw request body

Read getInputStream() before any body parsing, then hand the exact bytes to
Webhook.constructEvent with a 300s tolerance. Non-succeeded event types
return success=false instead of throwing, so Stripe still gets a 200 and
stops retrying. A missing orderNo metadata is a hard error.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: PaymentChannelResolver

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentChannelResolver.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentChannelResolverTest.java`

**Interfaces:**
- Consumes: `MockPaymentChannel` (Task 2), `StripePaymentChannel` (Tasks 4-5)
- Produces: `resolve(String region)` → `PaymentChannel`；`resolveByChannel(String channel)` → `PaymentChannel`

`StripePaymentChannel` 是条件 Bean（`@ConditionalOnBean(StripeClient.class)`），所以 resolver 必须接受它**不存在**的情况 —— 用 `Optional<StripePaymentChannel>` 注入。

- [x] **Step 1: Write failing test covering the routing table**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class PaymentChannelResolverTest {

    private final MockPaymentChannel mockChannel = mock(MockPaymentChannel.class);
    private final StripePaymentChannel stripeChannel = mock(StripePaymentChannel.class);

    private PaymentChannelResolver resolver(boolean stripeEnabled, boolean mockEnabled,
                                            boolean stripeBeanPresent) {
        return new PaymentChannelResolver(
            mockChannel,
            stripeBeanPresent ? Optional.of(stripeChannel) : Optional.empty(),
            stripeEnabled,
            mockEnabled);
    }

    @Test
    void shouldRouteEuToStripeWhenEnabled() {
        assertSame(stripeChannel, resolver(true, true, true).resolve("EU"));
    }

    @Test
    void shouldRouteEuToMockWhenStripeDisabled() {
        assertSame(mockChannel, resolver(false, true, false).resolve("EU"));
    }

    @Test
    void shouldAlwaysRouteCnToMock() {
        assertSame(mockChannel, resolver(true, true, true).resolve("CN"));
    }

    @Test
    void shouldFailClosedWhenBothDisabled() {
        assertThrows(ServiceUnavailableException.class,
            () -> resolver(false, false, false).resolve("EU"));
    }

    @Test
    void shouldFailClosedWhenStripeEnabledButBeanMissing() {
        assertThrows(ServiceUnavailableException.class,
            () -> resolver(true, false, false).resolve("EU"));
    }

    @Test
    void shouldResolveByChannelName() {
        PaymentChannelResolver r = resolver(true, true, true);
        assertSame(stripeChannel, r.resolveByChannel("stripe"));
        assertSame(mockChannel, r.resolveByChannel("alipay_mock"));
        assertSame(mockChannel, r.resolveByChannel("stripe_mock"));
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=PaymentChannelResolverTest`
Expected: FAIL with "PaymentChannelResolver does not exist"

- [x] **Step 3: Implement PaymentChannelResolver**

```java
package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PaymentChannelResolver {

    private final MockPaymentChannel mockChannel;
    private final Optional<StripePaymentChannel> stripeChannel;
    private final boolean stripeEnabled;
    private final boolean mockEnabled;

    public PaymentChannelResolver(
            MockPaymentChannel mockChannel,
            Optional<StripePaymentChannel> stripeChannel,
            @Value("${app.payment.stripe.enabled:false}") boolean stripeEnabled,
            @Value("${app.payment.mock-enabled:false}") boolean mockEnabled) {
        this.mockChannel = mockChannel;
        this.stripeChannel = stripeChannel;
        this.stripeEnabled = stripeEnabled;
        this.mockEnabled = mockEnabled;
    }

    public PaymentChannel resolve(String region) {
        if (!"CN".equals(region) && stripeEnabled && stripeChannel.isPresent()) {
            return stripeChannel.get();
        }
        if (mockEnabled) {
            return mockChannel;
        }
        throw new ServiceUnavailableException("支付渠道尚未配置");
    }

    public PaymentChannel resolveByChannel(String channel) {
        if (StripePaymentChannel.CHANNEL.equals(channel)) {
            if (stripeEnabled && stripeChannel.isPresent()) {
                return stripeChannel.get();
            }
            throw new ServiceUnavailableException("支付渠道尚未配置");
        }
        if (mockEnabled) {
            return mockChannel;
        }
        throw new ServiceUnavailableException("支付渠道尚未配置");
    }
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `cd backend && ./mvnw -q test -Dtest=PaymentChannelResolverTest`
Expected: 6 tests PASS

- [x] **Step 5: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentChannelResolver.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/payment/PaymentChannelResolverTest.java
git commit -m "feat(payment): route payment channels by region and config

EU falls to Stripe only when both the flag is on and the conditional bean
exists; CN always stays on mock this round. Both disabled keeps the existing
fail-closed 503 rather than silently accepting payments.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Wire TradeService to the Resolver

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/service/TradeService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/service/TradeServiceFailClosedTest.java`

**Interfaces:**
- Consumes: `PaymentChannelResolver.resolve(region)` and `.resolveByChannel(channel)` (Task 6)
- Produces: `pay()` 返回值新增 `clientSecret`；新方法 `notifyInternal(String channel, PaymentNotifyResult result)` 供 Task 8 的 controller 调用

**注意：** `TradeService.java` 是单行压缩风格，修改时保持该风格。`pay()` 用 `Map.of()` 构造返回值，**`Map.of()` 遇 null 抛 NPE**，所以 mock 的 `clientSecret` 必须是 `""`。

- [x] **Step 1: Update TradeServiceFailClosedTest for the new constructor**

`TradeService` 构造器将用 `PaymentChannelResolver` 替换 `mockEnabled`。先改测试：

```java
package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import org.junit.jupiter.api.Test;

class TradeServiceFailClosedTest {

    private final TradeMapper mapper = mock(TradeMapper.class);
    private final PaymentChannelResolver resolver = mock(PaymentChannelResolver.class);
    private final TradeService service = new TradeService(
            mapper,
            mock(UserGrowthService.class),
            mock(CouponLifecycleService.class),
            mock(NotificationService.class),
            "payment-secret-for-runtime-safety-tests-001",
            resolver
    );

    @Test
    void shouldRejectPaymentIntentWhenNoChannelConfigured() {
        when(resolver.resolve(org.mockito.ArgumentMatchers.anyString()))
            .thenThrow(new ServiceUnavailableException("支付渠道尚未配置"));

        assertThrows(ServiceUnavailableException.class, () -> service.pay(1L));
        verifyNoInteractions(mapper);
    }

    @Test
    void shouldRejectMockCompletionWhenNoChannelConfigured() {
        when(resolver.resolve(org.mockito.ArgumentMatchers.anyString()))
            .thenThrow(new ServiceUnavailableException("支付渠道尚未配置"));

        assertThrows(ServiceUnavailableException.class, () -> service.completeMockPayment(1L));
        verifyNoInteractions(mapper);
    }
}
```

原 `shouldRejectPaymentCallbackWhenMockPaymentIsDisabled` 删除 —— 验签已移出 `TradeService`，webhook 的 fail-closed 由 `PaymentChannelResolverTest` 的 `shouldFailClosedWhenBothDisabled` 覆盖。

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=TradeServiceFailClosedTest`
Expected: FAIL —— 构造器签名不匹配（编译错误）

- [x] **Step 3: Update the TradeService constructor**

将第 5 行的字段与构造器改为（保持单行风格）：

```java
 private final TradeMapper mapper;private final UserGrowthService userGrowthService;private final CouponLifecycleService couponLifecycleService;private final NotificationService notificationService;private final String secret;private final PaymentChannelResolver channelResolver;public TradeService(TradeMapper mapper,UserGrowthService userGrowthService,CouponLifecycleService couponLifecycleService,NotificationService notificationService,@Value("${app.payment.notify-secret}")String secret,PaymentChannelResolver channelResolver){this.mapper=mapper;this.userGrowthService=userGrowthService;this.couponLifecycleService=couponLifecycleService;this.notificationService=notificationService;this.secret=secret;this.channelResolver=channelResolver;}
```

加 import：`import com.tuowei.dazhongdianping.module.trade.payment.*;`

- [x] **Step 4: Rewrite pay() to use the resolver**

替换第 11 行：

```java
 @Transactional public Map<String,Object> pay(Long id){OrderRow o=requireOrder(id);PaymentChannel ch=channelResolver.resolve(o.getRegion());if(o.getStatus()!=1||o.getPayStatus()!=0)throw new IllegalArgumentException("订单当前不可支付");PaymentRow p=mapper.selectPayment(id);String clientSecret="";if(p==null){p=new PaymentRow();p.setOrderId(id);p.setOrderNo(o.getOrderNo());PaymentIntentResult intent=ch.createIntent(o,p);p.setChannel(intent.channel());p.setChannelTxn(intent.channelTxn());p.setAmount(o.getAmount());p.setCurrency(o.getCurrency());mapper.insertPayment(p);clientSecret=intent.clientSecret()==null?"":intent.clientSecret();}return Map.of("paymentId",p.getId(),"channel",p.getChannel(),"channelTxn",p.getChannelTxn(),"clientSecret",clientSecret,"orderNo",o.getOrderNo(),"amount",o.getAmount(),"currency",o.getCurrency());}
```

**已知限制（本轮接受）：** 重复调用 `/pay` 时走 `p!=null` 分支，`clientSecret` 返回 `""`。前端在同一次支付会话内持有首次拿到的 `clientSecret`，刷新页面后需先 `cancel` 再重新下单。修复需要持久化 `clientSecret` 或按 `channelTxn` 回查 Stripe，留待退款出账那一轮一并处理。

- [x] **Step 5: Replace notify() with notifyInternal()**

替换第 12 行。签名与验签逻辑已移入渠道，此处只做金额比对、幂等、发券、通知：

```java
 @Transactional public Map<String,Object> notifyInternal(String channel,PaymentNotifyResult r){PaymentRow p=mapper.selectPaymentByTxn(channel,r.channelTxn());if(p==null||!p.getOrderNo().equals(r.orderNo()))throw new NotFoundException("支付流水不存在");OrderRow o=mapper.selectOrderByNo(r.orderNo());if(o==null||o.getAmount().compareTo(r.amount())!=0)throw new IllegalArgumentException("支付金额不一致");if(p.getStatus()==1)return Map.of("processed",false,"orderNo",o.getOrderNo());p.setRawResponse(r.toString());mapper.markPaymentSuccess(p);if(mapper.markOrderPaid(o.getId(),channel)==1){userGrowthService.rewardForCompletedOrder(o.getUserId(),o.getId());if(mapper.countOrderCoupons(o.getId())==0){DealRow d=mapper.selectDeal(o.getDealId(),o.getRegion());for(int i=0;i<o.getQuantity();i++){CouponRow c=new CouponRow();c.setOrderId(o.getId());c.setUserId(o.getUserId());c.setDealId(o.getDealId());c.setShopId(o.getShopId());c.setCode("CP"+UUID.randomUUID().toString().replace("-","").substring(0,20).toUpperCase());c.setExpireAt(d.getValidEnd());mapper.insertCoupon(c);}}notifyOrderPaid(o);}return Map.of("processed",true,"orderNo",o.getOrderNo());}
```

- [x] **Step 6: Rewrite completeMockPayment()**

替换第 13 行。`channel.endsWith("_mock")` 守卫保留 —— Stripe 渠道名为 `stripe`，这条守卫自动挡住：

```java
 @Transactional public Map<String,Object> completeMockPayment(Long id){OrderRow o=requireOrder(id);channelResolver.resolve(o.getRegion());Map<String,Object> intent=pay(id);String channel=(String)intent.get("channel");if(!channel.endsWith("_mock"))throw new IllegalArgumentException("当前渠道不是模拟支付");String txn=(String)intent.get("channelTxn");notifyInternal(channel,new PaymentNotifyResult(o.getOrderNo(),txn,o.getAmount(),true));return orderMap(requireOrder(id),true);}
```

- [x] **Step 7: Delete the now-unused requirePaymentChannel()**

删除第 40 行的 `private void requirePaymentChannel(){...}`。渠道可用性判断已全部由 `channelResolver.resolve()` 承担。`sign()` 方法保留 —— `MockPaymentChannel` 有自己的副本，但 `TradeService` 其余测试仍可能引用，删除属独立清理，不在本轮范围。

- [x] **Step 8: Run the trade test suite**

Run: `cd backend && ./mvnw -q test -Dtest='Trade*,*PaymentChannel*'`
Expected: 全部 PASS

- [x] **Step 9: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/service/TradeService.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/service/TradeServiceFailClosedTest.java
git commit -m "refactor(payment): resolve channels through PaymentChannelResolver

pay() now asks the resolver for the region's channel and returns its
clientSecret (empty string for mock, since Map.of rejects null). notify()
splits into channel-owned verification and notifyInternal, which keeps the
existing amount check, idempotency, coupon issuance and notification.

completeMockPayment keeps its endsWith(\"_mock\") guard; naming the Stripe
channel \"stripe\" means that guard already blocks mock-completing a real
payment without a new branch.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Stripe Webhook Endpoint

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/controller/TradeController.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/controller/TradeWebhookControllerTest.java`

**Interfaces:**
- Consumes: `PaymentChannelResolver.resolveByChannel` (Task 6), `TradeService.notifyInternal` (Task 7)
- Produces: `POST /api/c/v1/pay/notify/stripe` endpoint

`/api/c/v1/pay/**` 不在 `WebMvcConfig.java:43-67` 的 `userAuthInterceptor` 路径列表内，Stripe 回调不会被登录拦截 —— 无需改 `WebMvcConfig`。

- [x] **Step 1: Write failing test**

```java
package com.tuowei.dazhongdianping.module.trade.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentNotifyResult;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.util.Map;
import org.junit.jupiter.api.Test;

class TradeWebhookControllerTest {

    private final TradeService service = mock(TradeService.class);
    private final PaymentChannelResolver resolver = mock(PaymentChannelResolver.class);
    private final TradeController controller = new TradeController(service, resolver);

    @Test
    void shouldProcessVerifiedStripeWebhook() {
        PaymentChannel channel = mock(PaymentChannel.class);
        PaymentNotifyResult verified =
            new PaymentNotifyResult("OD12345", "pi_test_1", new BigDecimal("100.00"), true);
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhook(request)).thenReturn(verified);
        when(service.notifyInternal(eq("stripe"), any(PaymentNotifyResult.class)))
            .thenReturn(Map.of("processed", true, "orderNo", "OD12345"));

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(true, response.getData().get("processed"));
        verify(service).notifyInternal(eq("stripe"), any(PaymentNotifyResult.class));
    }

    @Test
    void shouldAcknowledgeIgnoredEventWithoutTouchingTradeService() {
        PaymentChannel channel = mock(PaymentChannel.class);
        PaymentNotifyResult ignored = new PaymentNotifyResult(null, null, null, false);
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhook(request)).thenReturn(ignored);

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(false, response.getData().get("processed"));
        verifyNoInteractions(service);
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd backend && ./mvnw -q test -Dtest=TradeWebhookControllerTest`
Expected: FAIL —— `TradeController` 构造器只有一个参数，`notifyStripe` 不存在

- [x] **Step 3: Add resolver to the controller and implement the endpoint**

`TradeController.java` 第 4 行改为注入 resolver：

```java
 private final TradeService service;private final PaymentChannelResolver channelResolver;public TradeController(TradeService service,PaymentChannelResolver channelResolver){this.service=service;this.channelResolver=channelResolver;}
```

新增端点（放在现有 `notify` 方法之后）：

```java
 @PostMapping("/pay/notify/stripe") public ApiResponse<Map<String,Object>> notifyStripe(HttpServletRequest request){PaymentNotifyResult r=channelResolver.resolveByChannel("stripe").verifyWebhook(request);if(!r.success())return ApiResponse.success(Map.of("processed",false));return ApiResponse.success(service.notifyInternal("stripe",r));}
```

加 import：`import com.tuowei.dazhongdianping.module.trade.payment.*;import jakarta.servlet.http.HttpServletRequest;`

- [x] **Step 4: Update the existing mock notify endpoint**

原第 14 行 `notify(@PathVariable String channel,@Valid @RequestBody PaymentNotifyRequest request)` 调用的 `service.notify(...)` 已不存在。改为走渠道验签：

```java
 @PostMapping("/pay/notify/{channel}") public ApiResponse<Map<String,Object>> notify(@PathVariable String channel,HttpServletRequest request){PaymentNotifyResult r=channelResolver.resolveByChannel(channel).verifyWebhook(request);if(!r.success())return ApiResponse.success(Map.of("processed",false));return ApiResponse.success(service.notifyInternal(channel,r));}
```

`PaymentNotifyRequest` 仍被 `MockPaymentChannel` 用于反序列化，不要删除该 record。

- [x] **Step 5: Run tests to verify they pass**

Run: `cd backend && ./mvnw -q test -Dtest=TradeWebhookControllerTest`
Expected: 2 tests PASS

- [x] **Step 6: Run the full backend suite for regressions**

Run: `cd backend && ./mvnw -q test`
Expected: 全部 PASS。若 `TradeControllerTest` 因 `notify` 签名变化失败，按新签名（`HttpServletRequest` 携带 JSON body 与签名字段）更新其调用。

- [x] **Step 7: Commit**

```bash
git add backend/src/main/java/com/tuowei/dazhongdianping/module/trade/controller/TradeController.java backend/src/test/java/com/tuowei/dazhongdianping/module/trade/controller/TradeWebhookControllerTest.java
git commit -m "feat(payment): add Stripe webhook endpoint

POST /pay/notify/stripe reads the raw request and delegates verification to
the channel, so Stripe-Signature is checked against unparsed bytes. Ignored
event types return processed=false with HTTP 200 so Stripe stops retrying.
The generic /pay/notify/{channel} endpoint moves to the same channel-owned
verification path.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Web — Types, Dependency, and Localizations

**Files:**
- Modify: `web/package.json`
- Modify: `web/src/types/trade.ts:44`
- Modify: `web/src/core/web_trade_localizations.ts`

**Interfaces:**
- Produces: `PaymentIntent.clientSecret?: string`；新文案键 `stripePayment` / `stripePaymentFailed` / `stripeProcessing`，供 Task 10-11 使用

- [x] **Step 1: Install @stripe/stripe-js**

Run: `cd web && npm install --save-exact @stripe/stripe-js@1.54.2`
Expected: 安装成功，`package.json` 出现该依赖

- [x] **Step 2: Add clientSecret to the PaymentIntent type**

`web/src/types/trade.ts:44` 改为（保持单行风格）：

```typescript
export interface PaymentIntent { paymentId:number;channel:string;channelTxn:string;clientSecret?:string;orderNo:string;amount:number;currency:string }
```

- [x] **Step 3: Add localization keys to the interface**

`web_trade_localizations.ts` 的 `orderDetail` 接口块（`completeMockPayment` 附近，约第 90 行）新增三个键：

```typescript
    stripePayment: string
    stripePaymentFailed: string
    stripeProcessing: string
```

- [x] **Step 4: Add the CN copy**

在 CN 文案对象里（`completeMockPayment` 附近，约第 319 行）新增：

```typescript
    stripePayment: '使用银行卡支付',
    stripePaymentFailed: '银行卡支付失败',
    stripeProcessing: '正在确认支付结果…',
```

- [x] **Step 5: Add the EU copy**

在 EU 文案对象里（`mockPaymentFailed` 附近，约第 463 行）新增：

```typescript
    stripePayment: 'Pay by card',
    stripePaymentFailed: 'Card payment failed',
    stripeProcessing: 'Confirming your payment…',
```

- [x] **Step 6: Verify typecheck passes**

Run: `cd web && npx vue-tsc --noEmit`
Expected: 无错误。若报缺键，说明两个区域的文案对象没同步补齐 —— 两处都要有。

- [x] **Step 7: Commit**

```bash
git add web/package.json web/package-lock.json web/src/types/trade.ts web/src/core/web_trade_localizations.ts
git commit -m "feat(web): add Stripe types, dependency and copy

clientSecret is optional on PaymentIntent since mock returns an empty
string. Card payment copy lands in both CN and EU tables.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Web — useStripeCheckout Composable

**Files:**
- Create: `web/src/composables/useStripeCheckout.ts`
- Test: `web/src/composables/useStripeCheckout.test.ts`

**Interfaces:**
- Consumes: `@stripe/stripe-js` (Task 9)
- Produces: `useStripeCheckout()` returning `{ error, processing, ready, mount(el, clientSecret), confirm(), unmount() }`

Publishable key 从 `import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY` 读，不经后端。

- [x] **Step 1: Write the failing test**

```typescript
import { describe, expect, it, vi, beforeEach } from 'vitest'

const confirmCardPayment = vi.fn()
const mount = vi.fn()
const unmount = vi.fn()
const create = vi.fn(() => ({ mount, unmount }))
const elements = vi.fn(() => ({ create }))

vi.mock('@stripe/stripe-js', () => ({
  loadStripe: vi.fn(async () => ({ elements, confirmCardPayment })),
}))

import { useStripeCheckout } from './useStripeCheckout'

describe('useStripeCheckout', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    confirmCardPayment.mockReset()
  })

  it('mounts a card element and becomes ready', async () => {
    const checkout = useStripeCheckout('pk_test_key')
    const el = document.createElement('div')

    await checkout.mount(el, 'pi_1_secret_abc')

    expect(create).toHaveBeenCalledWith('card', expect.anything())
    expect(mount).toHaveBeenCalledWith(el)
    expect(checkout.ready.value).toBe(true)
    expect(checkout.error.value).toBe('')
  })

  it('returns true when Stripe confirms the payment', async () => {
    confirmCardPayment.mockResolvedValue({ paymentIntent: { status: 'succeeded' } })
    const checkout = useStripeCheckout('pk_test_key')
    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    const ok = await checkout.confirm()

    expect(ok).toBe(true)
    expect(checkout.processing.value).toBe(false)
  })

  it('surfaces the Stripe error message and returns false', async () => {
    confirmCardPayment.mockResolvedValue({ error: { message: 'Your card was declined.' } })
    const checkout = useStripeCheckout('pk_test_key')
    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    const ok = await checkout.confirm()

    expect(ok).toBe(false)
    expect(checkout.error.value).toBe('Your card was declined.')
    expect(checkout.processing.value).toBe(false)
  })

  it('refuses to confirm before mount', async () => {
    const checkout = useStripeCheckout('pk_test_key')

    const ok = await checkout.confirm()

    expect(ok).toBe(false)
    expect(confirmCardPayment).not.toHaveBeenCalled()
  })

  it('reports a missing publishable key instead of throwing', async () => {
    const checkout = useStripeCheckout('')

    await checkout.mount(document.createElement('div'), 'pi_1_secret_abc')

    expect(checkout.ready.value).toBe(false)
    expect(checkout.error.value).not.toBe('')
  })
})
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd web && npx vitest run --environment jsdom src/composables/useStripeCheckout.test.ts`
Expected: FAIL —— 模块不存在

- [x] **Step 3: Implement the composable**

```typescript
import { ref } from 'vue'
import { loadStripe, type Stripe, type StripeCardElement } from '@stripe/stripe-js'

export function useStripeCheckout(publishableKey: string) {
  const error = ref('')
  const processing = ref(false)
  const ready = ref(false)

  let stripe: Stripe | null = null
  let card: StripeCardElement | null = null
  let secret = ''

  async function mount(el: HTMLElement, clientSecret: string) {
    error.value = ''
    ready.value = false
    if (!publishableKey) {
      error.value = 'Stripe publishable key is not configured'
      return
    }
    try {
      stripe = await loadStripe(publishableKey)
      if (!stripe) {
        error.value = 'Stripe failed to load'
        return
      }
      secret = clientSecret
      card = stripe.elements().create('card', { hidePostalCode: true })
      card.mount(el)
      ready.value = true
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Stripe failed to load'
    }
  }

  async function confirm(): Promise<boolean> {
    if (!stripe || !card || !secret) return false
    processing.value = true
    error.value = ''
    try {
      const result = await stripe.confirmCardPayment(secret, { payment_method: { card } })
      if (result.error) {
        error.value = result.error.message || 'Card payment failed'
        return false
      }
      return result.paymentIntent?.status === 'succeeded'
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Card payment failed'
      return false
    } finally {
      processing.value = false
    }
  }

  function unmount() {
    card?.unmount()
    card = null
    ready.value = false
  }

  return { error, processing, ready, mount, confirm, unmount }
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `cd web && npx vitest run --environment jsdom src/composables/useStripeCheckout.test.ts`
Expected: 5 tests PASS

- [x] **Step 5: Commit**

```bash
git add web/src/composables/useStripeCheckout.ts web/src/composables/useStripeCheckout.test.ts
git commit -m "feat(web): add useStripeCheckout composable

Wrap Stripe Elements lifecycle behind mount/confirm/unmount with error and
processing refs. A missing publishable key surfaces as an error rather than
throwing, so the order page still renders.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Web — Branch OrderDetailView by clientSecret

**Files:**
- Modify: `web/src/views/OrderDetailView.vue`
- Test: `web/src/views/OrderDetailView.test.ts`

**Interfaces:**
- Consumes: `useStripeCheckout` (Task 10), `PaymentIntent.clientSecret` (Task 9)
- Produces: 订单页两条支付路径 —— `clientSecret` 非空走 Stripe Elements，为空走现有 mock-complete

- [x] **Step 1: Write the failing test**

在 `OrderDetailView.test.ts` 追加。既有 mock 路径的测试必须保持通过 —— 这是回归防线：

```typescript
it('shows the card form and hides mock-complete when clientSecret is present', async () => {
  vi.mocked(payOrder).mockResolvedValue({
    paymentId: 1, channel: 'stripe', channelTxn: 'pi_1',
    clientSecret: 'pi_1_secret_abc', orderNo: 'OD1', amount: 100, currency: 'EUR',
  })

  const wrapper = mountView()
  await flushPromises()
  await wrapper.find('[data-testid="order-pay"]').trigger('click')
  await flushPromises()

  expect(wrapper.find('[data-testid="stripe-card-element"]').exists()).toBe(true)
  expect(wrapper.find('[data-testid="mock-pay-complete"]').exists()).toBe(false)
})

it('keeps the mock-complete button when clientSecret is empty', async () => {
  vi.mocked(payOrder).mockResolvedValue({
    paymentId: 1, channel: 'alipay_mock', channelTxn: 'TX1',
    clientSecret: '', orderNo: 'OD1', amount: 100, currency: 'CNY',
  })

  const wrapper = mountView()
  await flushPromises()
  await wrapper.find('[data-testid="order-pay"]').trigger('click')
  await flushPromises()

  expect(wrapper.find('[data-testid="mock-pay-complete"]').exists()).toBe(true)
  expect(wrapper.find('[data-testid="stripe-card-element"]').exists()).toBe(false)
})
```

`mountView()` 沿用该测试文件已有的挂载辅助函数；若尚不存在，复用文件中现有的 `mount(OrderDetailView, {...})` 写法。给 `pay` 按钮补 `data-testid="order-pay"`（现有模板尚无该属性）。

- [x] **Step 2: Run test to verify it fails**

Run: `cd web && npx vitest run --environment jsdom src/views/OrderDetailView.test.ts`
Expected: FAIL —— `stripe-card-element` 不存在

- [x] **Step 3: Wire the composable into the script block**

`OrderDetailView.vue` 的 `<script setup>` 增加：

```typescript
import { useStripeCheckout } from '@/composables/useStripeCheckout'

const cardElement = ref<HTMLElement | null>(null)
const stripeCheckout = useStripeCheckout(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || '')
const needsStripe = computed(() => Boolean(intent.value?.clientSecret))
```

`pay()` 末尾在拿到 intent 后挂载卡片表单：

```typescript
async function pay() {
  acting.value = true
  errorMessage.value = ''
  try {
    intent.value = await payOrder(props.orderId)
    if (intent.value?.clientSecret) {
      await nextTick()
      if (cardElement.value) {
        await stripeCheckout.mount(cardElement.value, intent.value.clientSecret)
      }
    }
  } catch (error) {
    errorMessage.value = localizeWebTradeError(copy.value, error, copy.value.orderDetail.paymentFailed)
  } finally {
    acting.value = false
  }
}
```

`nextTick` 加入 `vue` 的 import。新增确认函数：

```typescript
async function confirmCard() {
  errorMessage.value = ''
  const ok = await stripeCheckout.confirm()
  if (!ok) {
    errorMessage.value = stripeCheckout.error.value || copy.value.orderDetail.stripePaymentFailed
    return
  }
  successMessage.value = copy.value.orderDetail.stripeProcessing
  stripeCheckout.unmount()
  intent.value = null
  await load()
}
```

**为什么确认后调 `load()`：** Stripe 确认成功只代表卡已授权，订单状态由 webhook 落库。`load()` 拉一次最新状态；若 webhook 尚未到达，页面显示 `stripeProcessing`，随后由既有 WebSocket `order.paid` 通知刷新。

- [x] **Step 4: Add the template branch**

把现有 mock-complete 按钮（约第 142-151 行）改为条件渲染，并在其前面插入卡片容器：

```html
<div v-if="needsStripe" class="stripe-card-block">
  <div ref="cardElement" data-testid="stripe-card-element" class="stripe-card-element"></div>
  <button
    class="primary-button"
    type="button"
    data-testid="stripe-pay-confirm"
    :disabled="!stripeCheckout.ready.value || stripeCheckout.processing.value"
    @click="confirmCard"
  >
    {{ copy.orderDetail.stripePayment }}
  </button>
</div>
<button
  v-if="intent && !needsStripe"
  class="primary-button"
  type="button"
  :disabled="acting"
  data-testid="mock-pay-complete"
  @click="complete"
>
  {{ copy.orderDetail.completeMockPayment(intent.channel) }}
</button>
```

给 `pay` 按钮加 `data-testid="order-pay"`。

- [x] **Step 5: Add styles for the card element**

在该组件 `<style scoped>` 末尾追加，沿用现有卡片体系与 40px 命中区：

```css
.stripe-card-block { display: flex; flex-direction: column; gap: 12px; width: 100%; }
.stripe-card-element {
  min-height: 40px;
  padding: 12px;
  border: 1px solid rgb(0 0 0 / 12%);
  border-radius: 8px;
  background: #fff;
}
```

- [x] **Step 6: Run tests to verify all pass**

Run: `cd web && npm test`
Expected: 全部 PASS，包括既有 OrderDetailView 测试（mock 路径回归防线）

- [x] **Step 7: Typecheck**

Run: `cd web && npx vue-tsc --noEmit`
Expected: 无错误

- [x] **Step 8: Commit**

```bash
git add web/src/views/OrderDetailView.vue web/src/views/OrderDetailView.test.ts
git commit -m "feat(web): branch order payment on clientSecret

A non-empty clientSecret mounts Stripe Elements and hides mock-complete;
an empty one keeps the existing mock path untouched. Confirming a card only
means Stripe authorized it, so the view reloads and waits for the webhook to
move the order to paid.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Flutter — clientSecret on PaymentIntent

**Files:**
- Modify: `app/lib/features/trade/trade_repository.dart:312-330`
- Test: `app/test/features/trade/trade_repository_test.dart`（若不存在则新建）

**Interfaces:**
- Produces: `PaymentIntent.clientSecret` field，供 Task 13 使用

`ThirdPartyConfig.stripePublishableKey` 与 `stripeEnabled` **已存在**（`app/lib/core/third_party_config.dart:8,21`），无需新建 —— 只需消费。

- [x] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';

void main() {
  group('PaymentIntent.fromJson', () {
    test('parses clientSecret when present', () {
      final intent = PaymentIntent.fromJson(<String, dynamic>{
        'channel': 'stripe',
        'orderNo': 'OD12345',
        'amount': 100.00,
        'currency': 'EUR',
        'clientSecret': 'pi_1_secret_abc',
      });

      expect(intent.clientSecret, 'pi_1_secret_abc');
      expect(intent.needsCardConfirmation, isTrue);
    });

    test('falls back to empty string when clientSecret is absent', () {
      final intent = PaymentIntent.fromJson(<String, dynamic>{
        'channel': 'alipay_mock',
        'orderNo': 'OD12346',
        'amount': 50.00,
        'currency': 'CNY',
      });

      expect(intent.clientSecret, '');
      expect(intent.needsCardConfirmation, isFalse);
    });
  });
}
```

导入包名以 `app/pubspec.yaml` 的 `name:` 字段为准；若不是 `dazhongdianping_app`，按实际值替换。

- [x] **Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/trade/trade_repository_test.dart`
Expected: FAIL —— `clientSecret` 与 `needsCardConfirmation` 不存在

- [x] **Step 3: Add the field and getter**

`trade_repository.dart:312` 的 `PaymentIntent` 改为：

```dart
class PaymentIntent {
  const PaymentIntent({
    required this.channel,
    required this.orderNo,
    required this.amount,
    required this.currency,
    this.clientSecret = '',
  });
  final String channel;
  final String orderNo;
  final num amount;
  final String currency;
  final String clientSecret;

  bool get needsCardConfirmation => clientSecret.trim().isNotEmpty;
```

`fromJson` 工厂增加一行（保持文件现有格式）：

```dart
        clientSecret: (json['clientSecret'] as String?) ?? '',
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd app && flutter test test/features/trade/trade_repository_test.dart`
Expected: 2 tests PASS

- [x] **Step 5: Commit**

```bash
git add app/lib/features/trade/trade_repository.dart app/test/features/trade/trade_repository_test.dart
git commit -m "feat(app): parse clientSecret on PaymentIntent

Defaults to an empty string so mock responses keep deserializing, with
needsCardConfirmation as the single branch point for the payment UI.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: Flutter — PaymentSheet on the Order Screen

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `app/lib/main.dart`
- Modify: `app/lib/features/trade/order_detail_screen.dart`

**Interfaces:**
- Consumes: `PaymentIntent.needsCardConfirmation` (Task 12), `ThirdPartyConfig.stripePublishableKey`（已存在）
- Produces: 真机可用的卡支付流程

- [x] **Step 1: Add flutter_stripe**

`app/pubspec.yaml` 的 `dependencies` 下加入：

```yaml
  flutter_stripe: ^11.4.0
```

Run: `cd app && flutter pub get`
Expected: 解析成功

- [x] **Step 2: Verify the Android minSdk floor**

`flutter_stripe` 要求 `minSdkVersion` ≥ 21，且 Android 端必须使用 `FlutterFragmentActivity`（不是 `FlutterActivity`）。

Run: `cd app && grep -rn "minSdk" android/app/build.gradle.kts && grep -n "class MainActivity" android/app/src/main/kotlin/**/MainActivity.kt`
Expected: minSdk ≥ 21。若 `MainActivity` 继承 `FlutterActivity`，改为 `FlutterFragmentActivity` 并同步 import —— 否则 PaymentSheet 在 Android 上抛运行时异常。

- [x] **Step 3: Initialize the publishable key at startup**

`app/lib/main.dart` 在 `runApp` 之前，仅当 key 非空时初始化：

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

// inside main(), before runApp:
const config = ThirdPartyConfig();
if (config.stripeEnabled) {
  Stripe.publishableKey = config.stripePublishableKey;
  await Stripe.instance.applySettings();
}
```

`main()` 需为 `Future<void> main() async` 且先调 `WidgetsFlutterBinding.ensureInitialized()`。若 `main.dart` 已有 `ThirdPartyConfig` 实例，复用它而不是新建。

- [x] **Step 4: Branch the payment action**

`order_detail_screen.dart` 的支付处理改为按 `needsCardConfirmation` 分支：

```dart
Future<void> _handlePay() async {
  setState(() => _acting = true);
  try {
    final intent = await widget.repository.payOrder(widget.orderId);
    if (intent.needsCardConfirmation) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Dazhongdianping',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      // Stripe 已授权；订单状态由 webhook 落库，这里只刷新
      await _reload();
    } else {
      await _completeMockPayment();
    }
  } on StripeException catch (e) {
    setState(() => _error = e.error.localizedMessage ?? _strings.paymentFailed);
  } catch (e) {
    setState(() => _error = _strings.paymentFailed);
  } finally {
    if (mounted) setState(() => _acting = false);
  }
}
```

`_reload()`、`_completeMockPayment()`、`_strings`、`_acting`、`_error` 沿用该文件现有成员名；若命名不同，按文件实际命名替换而不是新增字段。

**用户取消不是错误：** `presentPaymentSheet()` 在用户主动关闭支付面板时抛 `StripeException`，其 `error.code` 为 `FailureCode.Canceled`。在 `on StripeException` 分支里先判断该 code 并静默返回，不要显示错误提示。

- [x] **Step 5: Run analyze and tests**

Run: `cd app && flutter analyze && flutter test`
Expected: analyze 零问题，测试全部 PASS

- [x] **Step 6: Commit**

```bash
git add app/pubspec.yaml app/lib/main.dart app/lib/features/trade/order_detail_screen.dart
git commit -m "feat(app): present Stripe PaymentSheet for card payments

Reuse the existing ThirdPartyConfig.stripeEnabled gate so builds without a
publishable key skip Stripe init entirely and keep the mock path. Treat a
user-dismissed sheet as a cancel rather than a failure.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 14: End-to-End Verification with Stripe CLI

**Files:**
- Modify: `docs/当前已完成功能与SQL导入说明.md`

**Interfaces:**
- Consumes: 全部前序任务

本任务需要真实 Stripe test 凭证。若尚未获取，前 13 个任务的单元测试仍可全绿；本任务在拿到凭证后执行。

- [ ] **Step 1: Obtain test credentials**

在 Stripe Dashboard（test mode）取三项：

- `sk_test_...` → `APP_PAYMENT_STRIPE_SECRET_KEY`
- `pk_test_...` → web 的 `VITE_STRIPE_PUBLISHABLE_KEY`，app 的 `--dart-define=STRIPE_PUBLISHABLE_KEY=`
- `whsec_...` → `APP_PAYMENT_STRIPE_ENDPOINT_SECRET`（由 Step 2 的 `stripe listen` 输出给出）

Stripe test mode 只需邮箱注册，不需要公司主体或营业执照。

- [ ] **Step 2: Forward webhooks to the local backend**

Run: `stripe listen --forward-to localhost:8080/api/c/v1/pay/notify/stripe`
Expected: 输出 `Ready! Your webhook signing secret is whsec_...`。把该值设为 `APP_PAYMENT_STRIPE_ENDPOINT_SECRET` —— **`stripe listen` 的 secret 与 Dashboard 上的 endpoint secret 不同**，用错会导致签名一律失败。

- [ ] **Step 3: Start the backend with Stripe enabled**

```bash
cd backend && APP_PAYMENT_STRIPE_ENABLED=true \
  APP_PAYMENT_STRIPE_SECRET_KEY=sk_test_xxx \
  APP_PAYMENT_STRIPE_ENDPOINT_SECRET=whsec_xxx \
  APP_PAYMENT_MOCK_ENABLED=true \
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Expected: 正常启动，无 `StripeClient` 装配错误

- [ ] **Step 4: Place an EU order and pay with the test card**

用 web 前端（`VITE_STRIPE_PUBLISHABLE_KEY=pk_test_xxx npm run dev`）在 EU 区下单，卡号 `4242 4242 4242 4242`，任意未来有效期，任意 CVC。

Expected:
- `/pay` 响应含非空 `clientSecret`
- 卡片表单渲染，确认后无报错
- `stripe listen` 终端出现 `payment_intent.succeeded → 200`
- 订单状态转为已支付，券已生成

- [ ] **Step 5: Verify signature rejection**

Run: `curl -X POST localhost:8080/api/c/v1/pay/notify/stripe -H "Stripe-Signature: t=1,v1=deadbeef" -d '{}'`
Expected: HTTP 400，消息为"Stripe 回调签名非法"。**这一步必须验** —— 它证明验签真的生效，而不是被意外跳过。

- [ ] **Step 6: Verify CN is untouched**

在 CN 区下单并走 mock-complete。

Expected: `clientSecret` 为 `""`，mock-complete 按钮可见且可用，订单正常转已支付。

- [ ] **Step 7: Verify mock-complete cannot bypass Stripe**

对一个 EU 区 Stripe 订单调用 `POST /api/c/v1/orders/{id}/pay/mock-complete`。

Expected: HTTP 400，"当前渠道不是模拟支付"。

- [ ] **Step 8: Update the status doc**

在 `docs/当前已完成功能与SQL导入说明.md` 的支付章节，把"支付渠道尚未配置/仅 mock"更新为：EU 区 Stripe test mode 已打通（PaymentIntent → Elements/PaymentSheet → webhook 验签 → 发券），CN 区仍为 `alipay_mock`，真实退款出账与生产 switchover 未做。

- [ ] **Step 9: Commit**

```bash
git add docs/当前已完成功能与SQL导入说明.md
git commit -m "docs: record Stripe test-mode payment as verified

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Verification Summary

| 层 | 命令 | 覆盖 |
|---|---|---|
| 后端单元 | `cd backend && ./mvnw -q test` | 渠道实现、验签、路由表、fail-closed |
| Web 单元 | `cd web && npm test` | composable 状态机、订单页两条分支 |
| Web 类型 | `cd web && npx vue-tsc --noEmit` | `clientSecret` 契约 |
| Flutter | `cd app && flutter analyze && flutter test` | 模型解析、分支逻辑 |
| 集成 | Task 14 | 真实 Stripe 沙盒全链路 |

## Known Limitations (accepted this round)

- **重复 `/pay` 不返回 `clientSecret`** —— 已有 payment 行时走 `p!=null` 分支返回 `""`。刷新页面后需先取消订单再重下。修复需持久化 `clientSecret` 或按 `channelTxn` 回查 Stripe。
- ~~**退款不出账** —— `refund()` 仍只写本地审核行。~~ **已实现（提交 11da3b4）**：`StripePaymentChannel.refund` 调用 `stripeClient.refunds().create`，并经 `AdminTradeService.issueChannelRefund` 与 `MerchantTradeService.issueChannelRefund` 在 `@Transactional` 内 fail-closed 调用（渠道错误回滚审核，不留 approved-but-not-refunded）。test 模式下不出真实资金。本条原为本轮已知限制，事后已闭合。
- **CN 区无真实支付** —— 支付宝需国内企业主体；Stripe live 不支持中国大陆主体，需境外主体。
- **`TradeService.sign()` 与 `MockPaymentChannel.sign()` 重复** —— 独立清理项，不在本轮范围。






