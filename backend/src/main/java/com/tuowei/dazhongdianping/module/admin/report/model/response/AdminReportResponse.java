package com.tuowei.dazhongdianping.module.admin.report.model.response;

public record AdminReportResponse(
        Long id,
        String reportType,
        String reportTypeText,
        Long targetId,
        Integer targetType,
        String targetTypeText,
        Long reporterUserId,
        String reporterUserName,
        String reason,
        Integer status,
        String statusText,
        String region,
        String targetSummary,
        Long targetAuthorId,
        String targetAuthorName,
        Integer targetAuditStatus,
        Integer targetStatus,
        String targetStatusText,
        String createdAt
) {
}
