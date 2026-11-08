package com.tuowei.dazhongdianping.module.admin.groupbuy.model.response;

import java.util.List;

public record AdminGroupBuySummaryResponse(
        int windowHours,
        long totalTeams,
        long activeTeams,
        long formedTeams,
        long expiredTeams,
        long overdueActiveTeams,
        long memberOrders,
        long paidOrders,
        long pendingRefunds,
        long failedRefunds,
        long missingCouponOrders,
        long unreleasedInventoryOrders,
        List<AdminGroupBuyAlertResponse> alerts) {}
