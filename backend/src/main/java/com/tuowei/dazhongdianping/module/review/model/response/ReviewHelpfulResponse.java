package com.tuowei.dazhongdianping.module.review.model.response;

public record ReviewHelpfulResponse(
        Long reviewId,
        boolean voted,
        Integer helpfulCount
) {
}
