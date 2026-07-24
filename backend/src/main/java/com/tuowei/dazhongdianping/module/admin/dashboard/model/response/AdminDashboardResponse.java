package com.tuowei.dazhongdianping.module.admin.dashboard.model.response;

import java.util.List;
import java.util.Map;

public record AdminDashboardResponse(
        String region,
        long shopCount,
        long importBatchCount,
        long paidOrderCount,
        long pendingRefundCount,
        long pendingAuditTaskCount,
        long userCount,
        List<Map<String, Object>> pendingAuditBreakdown
) {
}
