package com.tuowei.dazhongdianping.module.auth.model.response;

public record UserExpertCertificationStatusResponse(
        Long id,
        Integer status,
        String statusText,
        String reason,
        String rejectReason,
        UserExpertCertificationBadgeResponse badge,
        String submittedAt,
        String reviewedAt,
        String effectiveStartAt,
        String effectiveEndAt
) {
}
