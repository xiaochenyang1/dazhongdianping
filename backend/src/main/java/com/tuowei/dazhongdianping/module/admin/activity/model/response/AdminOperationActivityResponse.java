package com.tuowei.dazhongdianping.module.admin.activity.model.response;

import com.fasterxml.jackson.databind.JsonNode;

public record AdminOperationActivityResponse(
        Long id,
        String region,
        Long cityId,
        String cityName,
        String name,
        String code,
        int channel,
        String channelText,
        int type,
        String typeText,
        int status,
        String statusText,
        String cover,
        String landingUrl,
        JsonNode rule,
        String startAt,
        String endAt,
        int itemCount
) {
}
