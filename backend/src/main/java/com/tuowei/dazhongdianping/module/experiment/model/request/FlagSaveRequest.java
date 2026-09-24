package com.tuowei.dazhongdianping.module.experiment.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record FlagSaveRequest(
        @NotBlank(message = "flagKey 不能为空") @Size(max = 64) String flagKey,
        @Size(max = 255) String description,
        @NotNull(message = "enabled 不能为空") Boolean enabled,
        @NotNull(message = "rolloutPercent 不能为空") @Min(0) @Max(100) Integer rolloutPercent
) {
}
