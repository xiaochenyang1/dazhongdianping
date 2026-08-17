package com.tuowei.dazhongdianping.module.trade.payment;

import com.stripe.StripeClient;
import com.stripe.exception.ApiConnectionException;
import com.stripe.exception.AuthenticationException;
import com.stripe.exception.InvalidRequestException;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.model.Refund;
import com.stripe.net.RequestOptions;
import com.stripe.net.Webhook;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.param.RefundCreateParams;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

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
            RequestOptions requestOptions = RequestOptions.builder()
                    .setIdempotencyKey("payment-intent-" + order.getOrderNo())
                    .build();
            PaymentIntent intent = stripeClient.paymentIntents().create(params, requestOptions);
            return new PaymentIntentResult(CHANNEL, intent.getId(), intent.getClientSecret());
        } catch (StripeException e) {
            throw translate(e);
        }
    }

    private static final String SUCCEEDED_EVENT = "payment_intent.succeeded";
    private static final java.util.Set<String> REFUND_EVENTS = java.util.Set.of(
            "refund.created",
            "refund.updated",
            "refund.failed"
    );
    private static final long TOLERANCE_SECONDS = 300L;

    @Override
    public ChannelWebhookResult verifyWebhookEvent(HttpServletRequest rawRequest) {
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

        if (REFUND_EVENTS.contains(event.getType())) {
            Refund refund = (Refund) event.getDataObjectDeserializer()
                    .getObject()
                    .orElseThrow(() -> new IllegalStateException("Stripe 回调事件缺少 Refund 对象"));
            BigDecimal amount = BigDecimal.valueOf(refund.getAmount()).movePointLeft(2).setScale(2);
            return ChannelWebhookResult.refundUpdated(
                    refund.getId(),
                    amount,
                    refundState(refund.getStatus()),
                    refund.getFailureReason()
            );
        }

        if (!SUCCEEDED_EVENT.equals(event.getType())) {
            return ChannelWebhookResult.ignored();
        }

        PaymentIntent intent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject()
                .orElseThrow(() -> new IllegalStateException("Stripe 回调事件缺少 PaymentIntent 对象"));

        String orderNo = intent.getMetadata() == null ? null : intent.getMetadata().get("orderNo");
        if (orderNo == null || orderNo.isBlank()) {
            throw new IllegalArgumentException("Stripe 回调缺少 orderNo metadata");
        }

        BigDecimal amount = BigDecimal.valueOf(intent.getAmount()).movePointLeft(2).setScale(2);
        return ChannelWebhookResult.paymentSucceeded(orderNo, intent.getId(), amount);
    }

    @Override
    public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
        ChannelWebhookResult result = verifyWebhookEvent(rawRequest);
        if (result.eventType() != ChannelWebhookResult.EventType.PAYMENT_SUCCEEDED) {
            return new PaymentNotifyResult(null, null, null, false);
        }
        return new PaymentNotifyResult(
                result.orderNo(), result.channelTxn(), result.amount(), true);
    }

    @Override
    public boolean supports(String region, String channel) {
        return CHANNEL.equals(channel);
    }

    @Override
    public RefundResult refund(
            PaymentRow payment,
            BigDecimal amount,
            String reason,
            String idempotencyKey) {
        RefundCreateParams.Builder builder = RefundCreateParams.builder()
                .setPaymentIntent(payment.getChannelTxn())
                .setAmount(toMinorUnits(amount));
        String trimmedReason = reason == null ? "" : reason.trim();
        if (StringUtils.hasText(trimmedReason)) {
            builder.putMetadata("reason", trimmedReason);
        }
        try {
            if (!StringUtils.hasText(idempotencyKey)) {
                throw new IllegalArgumentException("退款幂等键不能为空");
            }
            RequestOptions requestOptions = RequestOptions.builder()
                    .setIdempotencyKey(idempotencyKey.trim())
                    .build();
            Refund refund = stripeClient.refunds().create(builder.build(), requestOptions);
            BigDecimal refundedAmount = BigDecimal.valueOf(refund.getAmount()).movePointLeft(2).setScale(2);
            return new RefundResult(
                    CHANNEL,
                    refund.getId(),
                    refundedAmount,
                    refundState(refund.getStatus()),
                    refund.getFailureReason()
            );
        } catch (StripeException e) {
            throw translate(e);
        }
    }

    @Override
    public RefundResult queryRefund(String refundTxn) {
        if (!StringUtils.hasText(refundTxn)) {
            throw new IllegalArgumentException("退款单号不能为空");
        }
        try {
            Refund refund = stripeClient.refunds().retrieve(refundTxn.trim());
            BigDecimal refundedAmount = BigDecimal.valueOf(refund.getAmount()).movePointLeft(2).setScale(2);
            return new RefundResult(
                    CHANNEL,
                    refund.getId(),
                    refundedAmount,
                    refundState(refund.getStatus()),
                    refund.getFailureReason()
            );
        } catch (StripeException e) {
            throw translate(e);
        }
    }

    private RefundChannelState refundState(String status) {
        if ("succeeded".equalsIgnoreCase(status)) {
            return RefundChannelState.SUCCEEDED;
        }
        if ("failed".equalsIgnoreCase(status) || "canceled".equalsIgnoreCase(status)) {
            return RefundChannelState.FAILED;
        }
        return RefundChannelState.PENDING;
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
