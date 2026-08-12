package com.tuowei.dazhongdianping.module.trade.payment;

import java.math.BigDecimal;

public record RefundResult(
    String channel,
    String refundTxn,
    BigDecimal amount,
    boolean success
) {}
