package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewCommentReplyResponse(
        Long id,
        Long userId,
        String userName,
        String content
) {
}
