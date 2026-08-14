package com.tuowei.dazhongdianping.module.trade.payment;

import java.math.BigDecimal;

public record ChannelWebhookResult(
        EventType eventType,
        String orderNo,
        String channelTxn,
        String refundTxn,
        BigDecimal amount,
        RefundChannelState refundState,
        String failureReason
) {

    public enum EventType {
        PAYMENT_SUCCEEDED,
        REFUND_UPDATED,
        IGNORED
    }

    public static ChannelWebhookResult paymentSucceeded(
            String orderNo,
            String channelTxn,
            BigDecimal amount) {
        return new ChannelWebhookResult(
                EventType.PAYMENT_SUCCEEDED,
                orderNo,
                channelTxn,
                null,
                amount,
                null,
                ""
        );
    }

    public static ChannelWebhookResult refundUpdated(
            String refundTxn,
            BigDecimal amount,
            RefundChannelState refundState,
            String failureReason) {
        return new ChannelWebhookResult(
                EventType.REFUND_UPDATED,
                null,
                null,
                refundTxn,
                amount,
                refundState,
                failureReason == null ? "" : failureReason
        );
    }

    public static ChannelWebhookResult ignored() {
        return new ChannelWebhookResult(
                EventType.IGNORED,
                null,
                null,
                null,
                null,
                null,
                ""
        );
    }
}
