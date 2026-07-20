package com.tuowei.dazhongdianping.module.browse.model.response;

import java.math.BigDecimal;
import java.util.List;

public record ShopDetailResponse(
        Long id,
        String name,
        String coverUrl,
        BigDecimal score,
        BigDecimal tasteScore,
        BigDecimal envScore,
        BigDecimal serviceScore,
        BigDecimal pricePerCapita,
        String currency,
        String address,
        String phone,
        String businessHours,
        String summary,
        String categoryName,
        String cityName,
        String areaName,
        Boolean hasDeal,
        Boolean openNow,
        List<String> tags,
        List<PhotoResponse> photos,
        List<DishResponse> recommendedDishes
) {
}
