package com.tuowei.dazhongdianping.module.admin.activity.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record AdminOperationActivityStatusRequest(
        @NotNull(message = "status 不能为空")
        @Min(value = 0, message = "status 仅支持 0 到 4")
        @Max(value = 4, message = "status 仅支持 0 到 4")
        Integer status
) {
}
