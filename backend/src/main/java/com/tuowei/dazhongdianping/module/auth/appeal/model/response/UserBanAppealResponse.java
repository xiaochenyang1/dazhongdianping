package com.tuowei.dazhongdianping.module.auth.appeal.model.response;

public record UserBanAppealResponse(
        Long id,
        Integer status,
        String statusText,
        String reason,
        String rejectReason,
        String banReason,
        String submittedAt,
        String auditedAt
) {
}
