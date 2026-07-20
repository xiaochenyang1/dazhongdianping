package com.tuowei.dazhongdianping.module.auth.model.response;

public record PrivacyDeleteTaskResponse(
        Long id,
        Integer status,
        String statusText,
        String verifyType,
        String account,
        String reason,
        String coolingOffExpireAt,
        String completedAt,
        String cancelledAt,
        String createdAt,
        String updatedAt
) {
}
