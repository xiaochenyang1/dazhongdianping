package com.tuowei.dazhongdianping.module.review.model.response;

public record MerchantReplyResponse(
        String merchantName,
        String content,
        String repliedAt,
        String updatedAt
) {
}
