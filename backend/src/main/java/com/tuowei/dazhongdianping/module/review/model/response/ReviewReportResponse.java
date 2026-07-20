package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewReportResponse(
        Long id,
        Long reviewId,
        String reason,
        Integer status,
        String statusText,
        String createdAt
) {
}
