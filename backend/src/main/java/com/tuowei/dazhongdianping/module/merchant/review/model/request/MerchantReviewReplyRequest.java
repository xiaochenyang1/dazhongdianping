package com.tuowei.dazhongdianping.module.merchant.review.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MerchantReviewReplyRequest(
        @NotBlank
        @Size(max = 500)
        String content
) {
}
