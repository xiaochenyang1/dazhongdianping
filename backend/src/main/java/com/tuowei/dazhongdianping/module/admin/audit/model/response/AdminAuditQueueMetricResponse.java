package com.tuowei.dazhongdianping.module.admin.audit.model.response;

public record AdminAuditQueueMetricResponse(
        Integer bizType,
        String bizTypeText,
        Long pendingCount,
        String oldestPendingAt,
        Long oldestPendingAgeSeconds,
        Long overdueCount,
        Integer slaMinutes,
        Long processedCount,
        Long averageProcessingSeconds
) {
}
