package com.tuowei.dazhongdianping.module.admin.audit.model.response;

public record AdminAuditSlaAlertResponse(
        Long id,
        String region,
        Integer bizType,
        String bizTypeText,
        Integer status,
        String statusText,
        Long pendingCount,
        Long overdueCount,
        String oldestPendingAt,
        String firstOverdueAt,
        String lastDetectedAt,
        String resolvedAt
) {
}
