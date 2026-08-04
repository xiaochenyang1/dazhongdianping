package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewCommentReportResponse(
        Long id,
        Long reviewId,
        Long commentId,
        String reason,
        Integer status,
        String statusText,
        String createdAt
) {
}
