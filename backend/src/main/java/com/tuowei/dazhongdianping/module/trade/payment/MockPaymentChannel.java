package com.tuowei.dazhongdianping.module.trade.payment;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class MockPaymentChannel implements PaymentChannel {

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

    @Override
    public PaymentIntentResult createIntent(OrderRow order, PaymentRow payment) {
        String channel = "CN".equals(order.getRegion()) ? "alipay_mock" : "stripe_mock";
        String txn = "TX" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
        return new PaymentIntentResult(channel, txn, "");
    }

    @Override
    public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
        try {
            byte[] body = rawRequest.getInputStream().readAllBytes();
            com.tuowei.dazhongdianping.module.trade.model.request.PaymentNotifyRequest req =
                    objectMapper.readValue(body, com.tuowei.dazhongdianping.module.trade.model.request.PaymentNotifyRequest.class);

            if (!sign(req.orderNo(), req.channelTxn(), req.status(), req.amount())
                    .equalsIgnoreCase(req.signature())) {
                throw new IllegalArgumentException("支付回调签名非法");
            }

            if (!"SUCCESS".equalsIgnoreCase(req.status())) {
                throw new IllegalArgumentException("支付未成功");
            }

            return new PaymentNotifyResult(req.orderNo(), req.channelTxn(), req.amount(), true);
        } catch (java.io.IOException e) {
            throw new IllegalStateException("读取支付回调请求体失败", e);
        }
    }

    @Override
    public boolean supports(String region, String channel) {
        return channel != null && channel.endsWith("_mock");
    }

    @Override
    public RefundResult refund(PaymentRow payment, BigDecimal amount, String reason) {
        String channel = payment.getChannel() == null ? "alipay_mock" : payment.getChannel();
        String refundTxn = "RF" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
        BigDecimal refundedAmount = amount == null ? BigDecimal.ZERO.setScale(2) : amount.setScale(2);
        return new RefundResult(channel, refundTxn, refundedAmount, true);
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
