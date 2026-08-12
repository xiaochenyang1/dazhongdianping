package com.tuowei.dazhongdianping.module.trade.payment;

public record PaymentIntentResult(
    String channel,
    String channelTxn,
    String clientSecret
) {}
