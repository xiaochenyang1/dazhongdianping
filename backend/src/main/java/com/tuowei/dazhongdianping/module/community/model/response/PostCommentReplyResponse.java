package com.tuowei.dazhongdianping.module.community.model.response;

public record PostCommentReplyResponse(
        Long id,
        Long userId,
        String userName,
        String content
) {
}
