package com.tuowei.dazhongdianping.module.admin.geodata.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record GeoStatusRequest(
        @NotNull(message = "status 不能为空")
        @Min(value = 0, message = "status 只能为 0 或 1")
        @Max(value = 1, message = "status 只能为 0 或 1")
        Integer status
) {
}
