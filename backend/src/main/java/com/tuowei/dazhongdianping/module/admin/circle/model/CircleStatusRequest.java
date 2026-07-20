package com.tuowei.dazhongdianping.module.admin.circle.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CircleStatusRequest(@NotNull @Min(1) @Max(2) Integer status) {}
