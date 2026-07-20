package com.tuowei.dazhongdianping.module.review.model.response;

import java.math.BigDecimal;
import java.util.List;

public record UserReviewSummaryResponse(
        Long id,
        Long shopId,
        String shopName,
        String content,
        BigDecimal scoreOverall,
        Integer auditStatus,
        String auditStatusText,
        String auditRemark,
        Integer status,
        String statusText,
        List<String> tags,
        String createdAt,
        String updatedAt
) {
}
