package com.tuowei.dazhongdianping.module.community.model.response;

public record PostCommentReportResponse(
        Long id,
        Long postId,
        Long commentId,
        String reason,
        Integer status,
        String statusText,
        String createdAt
) {
}
