package com.tuowei.dazhongdianping.module.growth.model.request;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
public record GrowthRuleSaveRequest(@NotBlank String action, @NotBlank String actionName, @NotNull @Min(0) Integer growthValue, @NotNull @Min(0) Integer points, @NotNull @Min(0) Integer dailyLimit, @NotNull Boolean enabled) {}
