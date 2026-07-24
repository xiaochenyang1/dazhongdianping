package com.tuowei.dazhongdianping.module.activity.model.response;

public record PublicActivitySummaryResponse(
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
        String startAt,
        String endAt,
        int itemCount
) {
}
