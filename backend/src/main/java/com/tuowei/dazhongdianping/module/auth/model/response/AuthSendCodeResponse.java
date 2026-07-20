package com.tuowei.dazhongdianping.module.auth.model.response;

public record AuthSendCodeResponse(
        boolean sent,
        int expireSeconds,
        int nextRetrySeconds,
        String mockCode
) {
}
