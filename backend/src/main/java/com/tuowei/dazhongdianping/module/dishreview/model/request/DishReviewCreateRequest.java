package com.tuowei.dazhongdianping.module.dishreview.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record DishReviewCreateRequest(
        @NotNull(message = "score 不能为空")
        @Min(value = 1, message = "score 不能小于 1")
        @Max(value = 5, message = "score 不能大于 5")
        Integer score,
        @Size(max = 500, message = "content 不能超过 500 字")
        String content
) {
}
