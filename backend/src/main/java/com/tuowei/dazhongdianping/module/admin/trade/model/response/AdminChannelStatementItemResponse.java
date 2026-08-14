package com.tuowei.dazhongdianping.module.admin.trade.model.response;

import java.math.BigDecimal;

public record AdminChannelStatementItemResponse(
        Long id,
        Integer lineNo,
        String transactionType,
        String channelTransactionId,
        BigDecimal amount,
        String currency,
        String channelStatus,
        String occurredAt,
        String orderNo,
        String localBizType,
        Long localBizId,
        BigDecimal localAmount,
        String localCurrency,
        Integer localStatus,
        String reconcileStatus,
        String reconcileStatusText,
        String discrepancyReason
) {
}
