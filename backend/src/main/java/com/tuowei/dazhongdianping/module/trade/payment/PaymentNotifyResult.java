package com.tuowei.dazhongdianping.module.trade.payment;

import java.math.BigDecimal;

public record PaymentNotifyResult(
    String orderNo,
    String channelTxn,
    BigDecimal amount,
    boolean success
) {}
