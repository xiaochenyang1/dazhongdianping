package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.stripe.StripeClient;
import com.stripe.exception.AuthenticationException;
import com.stripe.model.PaymentIntent;
import com.stripe.model.Refund;
import com.stripe.service.PaymentIntentService;
import com.stripe.service.RefundService;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
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
        when(intentService.create(
                any(com.stripe.param.PaymentIntentCreateParams.class),
                any(com.stripe.net.RequestOptions.class)))
            .thenReturn(stripeIntent);

        PaymentIntentResult result = channel.createIntent(order(), new PaymentRow());

        assertEquals("stripe", result.channel());
        assertEquals("pi_test_123", result.channelTxn());
        assertEquals("pi_test_123_secret_abc", result.clientSecret());
    }

    @Test
    void shouldMapAuthenticationExceptionToServiceUnavailable() throws Exception {
        when(stripeClient.paymentIntents()).thenReturn(intentService);
        when(intentService.create(
                any(com.stripe.param.PaymentIntentCreateParams.class),
                any(com.stripe.net.RequestOptions.class)))
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

    @Test
    void shouldRefundPaymentIntentAndReturnSucceededReceipt() throws Exception {
        RefundService refundService = mock(RefundService.class);
        Refund stripeRefund = mock(Refund.class);
        when(stripeRefund.getId()).thenReturn("re_test_123");
        when(stripeRefund.getStatus()).thenReturn("succeeded");
        when(stripeRefund.getAmount()).thenReturn(8800L);
        when(stripeClient.refunds()).thenReturn(refundService);
        when(refundService.create(
                any(com.stripe.param.RefundCreateParams.class),
                any(com.stripe.net.RequestOptions.class)))
            .thenReturn(stripeRefund);

        PaymentRow payment = new PaymentRow();
        payment.setChannel("stripe");
        payment.setChannelTxn("pi_test_123");

        RefundResult result = channel.refund(
                payment, new BigDecimal("88.00"), "行程有变", "order-refund-123");

        assertTrue(result.success());
        assertEquals("stripe", result.channel());
        assertEquals("re_test_123", result.refundTxn());
        assertEquals(new BigDecimal("88.00"), result.amount());
    }

    @Test
    void shouldMapRefundFailureToServiceUnavailable() throws Exception {
        RefundService refundService = mock(RefundService.class);
        when(stripeClient.refunds()).thenReturn(refundService);
        when(refundService.create(
                any(com.stripe.param.RefundCreateParams.class),
                any(com.stripe.net.RequestOptions.class)))
            .thenThrow(new AuthenticationException("bad key", null, null, 401));

        PaymentRow payment = new PaymentRow();
        payment.setChannel("stripe");
        payment.setChannelTxn("pi_test_123");

        assertThrows(ServiceUnavailableException.class,
            () -> channel.refund(
                    payment, new BigDecimal("88.00"), "", "order-refund-123"));
    }

    /** Build a valid Stripe-Signature header the same way Stripe does. */
    private String testSignature(String payload, String secret) throws Exception {
        long timestamp = java.time.Instant.now().getEpochSecond();
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
}
