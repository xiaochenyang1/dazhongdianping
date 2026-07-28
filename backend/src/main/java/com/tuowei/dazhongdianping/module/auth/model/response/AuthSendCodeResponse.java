package com.tuowei.dazhongdianping.module.auth.model.response;

import com.fasterxml.jackson.annotation.JsonInclude;

public record AuthSendCodeResponse(
        boolean sent,
        int expireSeconds,
        int nextRetrySeconds,
        @JsonInclude(JsonInclude.Include.NON_EMPTY) String mockCode
) {
}
