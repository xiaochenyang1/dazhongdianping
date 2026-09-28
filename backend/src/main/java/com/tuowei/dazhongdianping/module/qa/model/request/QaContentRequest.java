package com.tuowei.dazhongdianping.module.qa.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 提问/回答的内容请求。 */
public record QaContentRequest(
        @NotBlank @Size(max = 500) String content
) {
}
