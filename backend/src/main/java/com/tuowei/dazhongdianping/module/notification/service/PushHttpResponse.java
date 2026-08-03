package com.tuowei.dazhongdianping.module.notification.service;

public record PushHttpResponse(int status, String body) {

    public boolean isSuccessful() {
        return status >= 200 && status < 300;
    }

    public boolean isRetryable() {
        return status == 408 || status == 425 || status == 429 || status >= 500;
    }
}
