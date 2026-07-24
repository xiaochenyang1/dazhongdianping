package com.tuowei.dazhongdianping.module.admin.sensitiveword.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminSensitiveWordSaveRequest(
        @NotBlank(message = "word 不能为空")
        @Size(max = 64, message = "word 不能超过 64 字")
        String word,
        @Size(max = 255, message = "remark 不能超过 255 字")
        String remark
) {
}
