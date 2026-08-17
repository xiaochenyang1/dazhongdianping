package com.tuowei.dazhongdianping.module.admin.trade.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class ChannelStatementMatchRow {
    private String bizType;
    private Long bizId;
    private Long orderId;
    private String orderNo;
    private BigDecimal amount;
    private String currency;
    private Integer status;
    private String channelTransactionId;
}
