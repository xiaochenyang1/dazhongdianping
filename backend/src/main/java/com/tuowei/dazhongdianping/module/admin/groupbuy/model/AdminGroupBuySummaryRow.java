package com.tuowei.dazhongdianping.module.admin.groupbuy.model;

import lombok.Data;

@Data
public class AdminGroupBuySummaryRow {
    private Long totalTeams;
    private Long activeTeams;
    private Long formedTeams;
    private Long expiredTeams;
    private Long overdueActiveTeams;
    private Long memberOrders;
    private Long paidOrders;
    private Long pendingRefunds;
    private Long failedRefunds;
    private Long missingCouponOrders;
    private Long unreleasedInventoryOrders;
}
