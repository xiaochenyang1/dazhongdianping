package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewLikeResponse(
        Long reviewId,
        boolean liked,
        Integer likeCount
) {
}
