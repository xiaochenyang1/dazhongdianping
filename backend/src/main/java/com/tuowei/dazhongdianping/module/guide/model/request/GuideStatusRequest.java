package com.tuowei.dazhongdianping.module.guide.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record GuideStatusRequest(
        @NotNull(message = "status 不能为空") @Min(1) @Max(2) Integer status
) {
}
