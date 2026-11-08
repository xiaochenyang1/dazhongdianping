package com.tuowei.dazhongdianping.module.admin.groupbuy.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminGroupBuyFailedRefundRow {
    private Long refundId;
    private Long orderId;
    private String orderNo;
    private Long teamId;
    private String campaignTitle;
    private String shopName;
    private BigDecimal amount;
    private String currency;
    private String channel;
    private String channelRefundTxn;
    private String channelStatus;
    private String channelFailureReason;
    private Integer refundStatus;
    private Long auditBy;
    private String auditReason;
    private LocalDateTime auditedAt;
    private LocalDateTime updatedAt;
}
