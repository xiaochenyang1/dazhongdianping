package com.tuowei.dazhongdianping.module.activity.model.response;

import com.fasterxml.jackson.databind.JsonNode;

public record PublicActivityItemResponse(
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
        String linkUrl
) {
}
