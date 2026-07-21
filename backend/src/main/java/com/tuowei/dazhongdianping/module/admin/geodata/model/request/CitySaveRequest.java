package com.tuowei.dazhongdianping.module.admin.geodata.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CitySaveRequest(
        @NotBlank(message = "code 不能为空")
        @Size(max = 32, message = "code 最长为 32 个字符")
        String code,
        @NotBlank(message = "name 不能为空")
        @Size(max = 64, message = "name 最长为 64 个字符")
        String name,
        @NotNull(message = "sortNo 不能为空")
        @Min(value = 0, message = "sortNo 不能小于 0")
        @Max(value = 999999, message = "sortNo 不能大于 999999")
        Integer sortNo
) {
}
