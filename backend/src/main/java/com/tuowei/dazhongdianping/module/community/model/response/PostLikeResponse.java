package com.tuowei.dazhongdianping.module.community.model.response;

public record PostLikeResponse(Long postId, boolean liked, Integer likeCount) {
}
