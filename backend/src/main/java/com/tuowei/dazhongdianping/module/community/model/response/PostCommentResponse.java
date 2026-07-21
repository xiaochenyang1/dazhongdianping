package com.tuowei.dazhongdianping.module.community.model.response;

import java.util.List;

public record PostCommentResponse(
        Long id,
        Long postId,
        Long userId,
        String userName,
        String content,
        Long parentId,
        PostCommentReplyResponse replyTo,
        List<PostCommentResponse> replies,
        boolean mine,
        String createdAt
) {
}
