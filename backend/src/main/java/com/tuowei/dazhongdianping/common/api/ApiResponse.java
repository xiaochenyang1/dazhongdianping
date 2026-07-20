package com.tuowei.dazhongdianping.common.api;

import com.tuowei.dazhongdianping.common.trace.TraceIdContext;

public record ApiResponse<T>(
        int code,
        String message,
        String messageKey,
        T data,
        String traceId
) {

    public static <T> ApiResponse<T> success(T data) {
        return success("查询成功", "common.success", data);
    }

    public static <T> ApiResponse<T> success(String message, String messageKey, T data) {
        return new ApiResponse<>(0, message, messageKey, data, TraceIdContext.getTraceId());
    }

    public static ApiResponse<Void> error(int code, String message, String messageKey) {
        return new ApiResponse<>(code, message, messageKey, null, TraceIdContext.getTraceId());
    }
}
