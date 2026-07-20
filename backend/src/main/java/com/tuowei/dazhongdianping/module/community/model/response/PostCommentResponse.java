package com.tuowei.dazhongdianping.module.community.model.response;

public record PostCommentResponse(
        Long id, Long postId, Long userId, String userName, String content, String createdAt
) {
}
