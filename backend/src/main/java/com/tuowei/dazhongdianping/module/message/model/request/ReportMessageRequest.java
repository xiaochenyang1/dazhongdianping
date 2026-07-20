package com.tuowei.dazhongdianping.module.message.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ReportMessageRequest(@NotNull @Min(1) @Max(2) Integer targetType,
                                   @NotNull Long targetId,
                                   @NotBlank @Size(max = 255) String reason) {}
