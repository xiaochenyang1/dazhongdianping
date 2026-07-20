package com.tuowei.dazhongdianping.module.rank.model.response;

import java.util.List;

public record RankDetailResponse(
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
        String updatedAt,
        List<RankItemResponse> items
) {
}
