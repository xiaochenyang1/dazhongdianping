package com.tuowei.dazhongdianping.module.community.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PostCommentCreateRequest(
        @NotBlank(message = "content 不能为空")
        @Size(max = 500, message = "content 不能超过 500 字")
        String content
) {
}
