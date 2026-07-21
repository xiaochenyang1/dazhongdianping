package com.tuowei.dazhongdianping.module.admin.activity.model.request;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminOperationActivityItemSaveRequest(
        @NotNull(message = "targetType 不能为空")
        @Min(value = 1, message = "targetType 仅支持 1 到 6")
        @Max(value = 6, message = "targetType 仅支持 1 到 6")
        Integer targetType,
        @NotNull(message = "targetId 不能为空")
        @Min(value = 0, message = "targetId 不能小于 0")
        Long targetId,
        @NotBlank(message = "title 不能为空")
        @Size(max = 128, message = "title 不能超过 128 字")
        String title,
        @Size(max = 255, message = "subtitle 不能超过 255 字")
        String subtitle,
        @NotBlank(message = "image 不能为空")
        @Size(max = 255, message = "image 不能超过 255 字")
        String image,
        @NotNull(message = "sort 不能为空")
        @Min(value = 0, message = "sort 不能小于 0")
        Integer sort,
        JsonNode extra
) {
}
