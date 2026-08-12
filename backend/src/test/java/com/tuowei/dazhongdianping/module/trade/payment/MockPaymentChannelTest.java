package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import org.junit.jupiter.api.Test;

class MockPaymentChannelTest {

    private final TradeMapper mapper = mock(TradeMapper.class);
    private final String secret = "test-secret-001";
    private final MockPaymentChannel channel = new MockPaymentChannel(mapper, secret, new ObjectMapper());

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
        assertEquals(26, result.channelTxn().length());
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

    @Test
    void shouldReturnSuccessRefundEchoingOriginalChannel() {
        PaymentRow payment = new PaymentRow();
        payment.setChannel("stripe_mock");
        payment.setChannelTxn("TX123456789012345678901234");
        BigDecimal amount = new BigDecimal("88.00");

        RefundResult result = channel.refund(payment, amount, "用户申请退款");

        assertTrue(result.success());
        assertEquals("stripe_mock", result.channel());
        assertEquals(new BigDecimal("88.00"), result.amount());
        assertTrue(result.refundTxn().startsWith("RF"));
        assertEquals(26, result.refundTxn().length());
    }

    @Test
    void shouldFallbackToAlipayMockWhenPaymentChannelMissing() {
        PaymentRow payment = new PaymentRow();
        payment.setChannelTxn("TX123456789012345678901234");

        RefundResult result = channel.refund(payment, new BigDecimal("10.00"), "");

        assertTrue(result.success());
        assertEquals("alipay_mock", result.channel());
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
}
