package com.tuowei.dazhongdianping.module.review.model.response;

import java.util.List;

public record ReviewCommentResponse(
        Long id,
        Long reviewId,
        Long userId,
        String userName,
        String content,
        Long parentId,
        ReviewCommentReplyResponse replyTo,
        List<ReviewCommentResponse> replies,
        boolean mine,
        String createdAt
) {
}
