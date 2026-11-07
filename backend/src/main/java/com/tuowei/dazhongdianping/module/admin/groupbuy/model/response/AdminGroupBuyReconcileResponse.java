package com.tuowei.dazhongdianping.module.admin.groupbuy.model.response;

public record AdminGroupBuyReconcileResponse(
        long teamId,
        int teamStatus,
        int expiredOrdersProcessed,
        int vouchersIssued,
        int failures,
        AdminGroupBuyTeamResponse team) {}
