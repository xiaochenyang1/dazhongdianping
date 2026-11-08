package com.tuowei.dazhongdianping.module.admin.groupbuy.model.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AdminGroupBuyFailedRefundResponse(
        long refundId,
        long orderId,
        String orderNo,
        long teamId,
        String campaignTitle,
        String shopName,
        BigDecimal amount,
        String currency,
        String channel,
        String channelRefundTxn,
        String channelStatus,
        String channelFailureReason,
        int refundStatus,
        Long auditBy,
        String auditReason,
        LocalDateTime auditedAt,
        LocalDateTime updatedAt) {}
