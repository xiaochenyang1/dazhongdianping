package com.tuowei.dazhongdianping.module.notification.service;

public record PushSendResult(
        boolean success,
        boolean retryable,
        boolean invalidToken,
        String provider,
        String errorCode
) {

    public static PushSendResult success(String provider) {
        return new PushSendResult(true, false, false, provider, "");
    }

    public static PushSendResult retryable(String provider, String errorCode) {
        return new PushSendResult(false, true, false, provider, errorCode);
    }

    public static PushSendResult invalidToken(String provider, String errorCode) {
        return new PushSendResult(false, false, true, provider, errorCode);
    }

    public static PushSendResult failed(String provider, String errorCode) {
        return new PushSendResult(false, false, false, provider, errorCode);
    }
}
