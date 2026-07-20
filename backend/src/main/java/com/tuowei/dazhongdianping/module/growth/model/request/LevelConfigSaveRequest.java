package com.tuowei.dazhongdianping.module.growth.model.request;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
public record LevelConfigSaveRequest(@NotNull @Min(0) Integer minGrowth, @NotBlank String levelName, String icon, @NotBlank String privilegeJson, @NotNull Boolean enabled) {}
