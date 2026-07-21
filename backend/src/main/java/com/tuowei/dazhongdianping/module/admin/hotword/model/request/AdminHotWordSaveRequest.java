package com.tuowei.dazhongdianping.module.admin.hotword.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminHotWordSaveRequest(
        @NotBlank(message = "keyword 不能为空")
        @Size(max = 64, message = "keyword 不能超过 64 字")
        String keyword,
        @NotNull(message = "sortNo 不能为空")
        @Min(value = 0, message = "sortNo 不能小于 0")
        Integer sortNo
) {
}
