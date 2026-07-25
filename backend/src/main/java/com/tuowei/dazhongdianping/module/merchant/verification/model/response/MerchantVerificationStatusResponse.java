package com.tuowei.dazhongdianping.module.merchant.verification.model.response;

import java.util.List;

public record MerchantVerificationStatusResponse(
        Long id,
        Integer status,
        String statusText,
        String reason,
        List<String> evidenceUrls,
        String rejectReason,
        MerchantVerificationBadgeResponse badge,
        String submittedAt,
        String auditedAt,
        String effectiveStartAt,
        String effectiveEndAt
) {
}
