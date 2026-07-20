package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewCommentResponse(
        Long id,
        Long reviewId,
        Long userId,
        String userName,
        String content,
        boolean mine,
        String createdAt
) {
}
