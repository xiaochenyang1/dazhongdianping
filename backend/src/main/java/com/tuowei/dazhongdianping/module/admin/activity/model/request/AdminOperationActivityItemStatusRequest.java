package com.tuowei.dazhongdianping.module.admin.activity.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record AdminOperationActivityItemStatusRequest(
        @NotNull(message = "status 不能为空")
        @Min(value = 1, message = "status 仅支持 1 或 2")
        @Max(value = 2, message = "status 仅支持 1 或 2")
        Integer status
) {
}
