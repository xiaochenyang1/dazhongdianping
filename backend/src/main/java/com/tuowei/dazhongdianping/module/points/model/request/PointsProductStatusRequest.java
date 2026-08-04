package com.tuowei.dazhongdianping.module.points.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PointsProductStatusRequest {

    @NotNull(message = "status 不能为空")
    @Min(value = 0, message = "status 仅支持 0/1")
    @Max(value = 1, message = "status 仅支持 0/1")
    private Integer status;
}
