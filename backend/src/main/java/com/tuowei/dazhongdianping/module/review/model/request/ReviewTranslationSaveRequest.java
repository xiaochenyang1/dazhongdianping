package com.tuowei.dazhongdianping.module.review.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ReviewTranslationSaveRequest(
        @NotBlank(message = "targetLang 不能为空")
        @Size(max = 8, message = "targetLang 不能超过 8 个字符")
        String targetLang,
        @NotBlank(message = "content 不能为空")
        @Size(max = 2000, message = "content 不能超过 2000 字")
        String content
) {
}
