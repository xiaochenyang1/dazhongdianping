package com.tuowei.dazhongdianping.module.merchant.review.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record MerchantReviewAppealSaveRequest(
        @NotBlank
        @Size(min = 10, max = 500)
        String reason,
        @NotNull
        @Size(max = 6)
        List<@NotBlank @Size(max = 255) String> evidenceUrls
) {
}
