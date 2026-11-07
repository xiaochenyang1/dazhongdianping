package com.tuowei.dazhongdianping.module.admin.groupbuy.model.response;

import java.time.LocalDateTime;

public record AdminGroupBuyTeamResponse(
        long id,
        long campaignId,
        String campaignTitle,
        long shopId,
        String shopName,
        long cityId,
        String region,
        int status,
        String statusText,
        int memberCount,
        int paidCount,
        int groupSize,
        long memberOrders,
        long paidOrders,
        long pendingRefunds,
        long failedRefunds,
        long missingCouponOrders,
        long unreleasedInventoryOrders,
        boolean problem,
        LocalDateTime expireAt,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {}
