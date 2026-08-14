package com.tuowei.dazhongdianping.module.admin.trade.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ChannelStatementItemRow {
    private Long id;
    private Long batchId;
    private Integer lineNo;
    private String transactionType;
    private String channelTransactionId;
    private BigDecimal amount;
    private String currency;
    private String channelStatus;
    private String occurredAt;
    private String orderNo;
    private String localBizType;
    private Long localBizId;
    private BigDecimal localAmount;
    private String localCurrency;
    private Integer localStatus;
    private String reconcileStatus;
    private String discrepancyReason;
    private String rawData;
    private LocalDateTime createdAt;
}
