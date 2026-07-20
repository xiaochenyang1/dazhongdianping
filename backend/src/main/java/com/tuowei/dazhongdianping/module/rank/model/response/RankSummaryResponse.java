package com.tuowei.dazhongdianping.module.rank.model.response;

public record RankSummaryResponse(
        Long id,
        String name,
        Integer type,
        String typeText,
        String region,
        Long cityId,
        String cityName,
        Long categoryId,
        String categoryName,
        String period,
        Integer itemCount,
        String coverUrl,
        String topShopName,
        String updatedAt
) {
}
