package com.tuowei.dazhongdianping.module.admin.audit.model.response;

public record AdminAuditLogResponse(
        Long id,
        Long adminId,
        String adminAccount,
        String adminName,
        String action,
        String target,
        String detail,
        String ip,
        String createdAt
) {
}
