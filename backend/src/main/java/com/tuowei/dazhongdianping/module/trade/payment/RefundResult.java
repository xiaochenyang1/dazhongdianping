package com.tuowei.dazhongdianping.module.trade.payment;

import java.math.BigDecimal;

public record RefundResult(
        String channel,
        String refundTxn,
        BigDecimal amount,
        RefundChannelState state,
        String failureReason
) {

    public RefundResult(String channel, String refundTxn, BigDecimal amount, boolean success) {
        this(
                channel,
                refundTxn,
                amount,
                success ? RefundChannelState.SUCCEEDED : RefundChannelState.FAILED,
                ""
        );
    }

    public boolean success() {
        return state == RefundChannelState.SUCCEEDED;
    }

    public boolean pending() {
        return state == RefundChannelState.PENDING;
    }
}
