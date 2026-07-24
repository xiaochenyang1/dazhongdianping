package com.tuowei.dazhongdianping.module.activity.model.response;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;

public record PublicActivityDetailResponse(
        Long id,
        String name,
        String code,
        String region,
        Long cityId,
        String cityName,
        int channel,
        String channelText,
        int type,
        String typeText,
        String cover,
        String landingUrl,
        JsonNode rule,
        String startAt,
        String endAt,
        List<PublicActivityItemResponse> items
) {
}
