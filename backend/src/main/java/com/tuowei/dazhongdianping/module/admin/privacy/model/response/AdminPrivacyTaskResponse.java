package com.tuowei.dazhongdianping.module.admin.privacy.model.response;

import java.util.List;

public record AdminPrivacyTaskResponse(
        Long id,
        Integer taskType,
        String taskTypeText,
        Long userId,
        String userNickname,
        String account,
        Integer status,
        String statusText,
        List<String> modules,
        String format,
        String fileName,
        String failReason,
        String verifyType,
        String reason,
        String expireAt,
        String coolingOffExpireAt,
        String completedAt,
        String cancelledAt,
        String createdAt,
        String updatedAt
) {
}
