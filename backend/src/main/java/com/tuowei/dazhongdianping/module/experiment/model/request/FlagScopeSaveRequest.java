package com.tuowei.dazhongdianping.module.experiment.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;

public record FlagScopeSaveRequest(
        @NotBlank @Pattern(regexp = "city|shop|campaign", message = "scopeType 只允许 city、shop、campaign")
        String scopeType,
        @NotNull @Positive Long scopeId,
        @NotNull Boolean enabled,
        @NotNull @Min(0) @Max(100) Integer rolloutPercent) {}
