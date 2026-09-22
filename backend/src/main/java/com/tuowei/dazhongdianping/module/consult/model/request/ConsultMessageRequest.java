package com.tuowei.dazhongdianping.module.consult.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 发送咨询消息的请求。 */
public record ConsultMessageRequest(
        @NotBlank @Size(max = 1000) String content
) {
}
