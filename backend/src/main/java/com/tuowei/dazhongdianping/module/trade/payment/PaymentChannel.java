package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;

public interface PaymentChannel {
    PaymentIntentResult createIntent(OrderRow order, PaymentRow payment);
    PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest);

    default ChannelWebhookResult verifyWebhookEvent(HttpServletRequest rawRequest) {
        PaymentNotifyResult result = verifyWebhook(rawRequest);
        return result == null || !result.success()
                ? ChannelWebhookResult.ignored()
                : ChannelWebhookResult.paymentSucceeded(
                        result.orderNo(), result.channelTxn(), result.amount());
    }
    boolean supports(String region, String channel);

    /**
     * Issue a refund for {@code amount} against the original {@code payment}.
     * <p>Implementations MUST fail-closed: any channel error propagates so the
     * caller can persist a succeeded, pending or failed channel state. Transport
     * errors and indeterminate responses still propagate so the audit remains
     * fail-closed.
     *
     * @param payment the original captured payment (carries {@code channel} + {@code channelTxn})
     * @param amount  refund amount in major units (same currency/scale as the payment)
     * @param reason  human-readable refund reason, may be blank
     * @return channel refund receipt (channel, channel refund txn id, amount, success)
     */
    RefundResult refund(
            PaymentRow payment,
            BigDecimal amount,
            String reason,
            String idempotencyKey
    );

    default RefundResult queryRefund(String refundTxn) {
        throw new UnsupportedOperationException("当前支付渠道不支持主动查询退款");
    }
}
