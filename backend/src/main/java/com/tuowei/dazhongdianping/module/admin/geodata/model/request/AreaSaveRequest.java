package com.tuowei.dazhongdianping.module.admin.geodata.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record AreaSaveRequest(
        @NotNull(message = "cityId 不能为空")
        @Positive(message = "cityId 必须大于 0")
        Long cityId,
        @NotBlank(message = "name 不能为空")
        @Size(max = 64, message = "name 最长为 64 个字符")
        String name,
        @NotNull(message = "sortNo 不能为空")
        @Min(value = 0, message = "sortNo 不能小于 0")
        @Max(value = 999999, message = "sortNo 不能大于 999999")
        Integer sortNo
) {
}
