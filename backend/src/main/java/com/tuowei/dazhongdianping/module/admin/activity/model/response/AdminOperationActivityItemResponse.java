package com.tuowei.dazhongdianping.module.admin.activity.model.response;

import com.fasterxml.jackson.databind.JsonNode;

public record AdminOperationActivityItemResponse(
        Long id,
        Long activityId,
        int targetType,
        String targetTypeText,
        Long targetId,
        String targetName,
        String title,
        String subtitle,
        String image,
        int sort,
        JsonNode extra,
        int status,
        String statusText
) {
}
