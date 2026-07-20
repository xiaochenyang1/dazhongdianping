package com.tuowei.dazhongdianping.module.admin.management.model.response;

import java.math.BigDecimal;
import java.util.List;

public record AdminShopDetailResponse(
        Long id,
        Long merchantId,
        String merchantName,
        String region,
        Long categoryId,
        String categoryName,
        Long cityId,
        String cityName,
        Long areaId,
        String areaName,
        String name,
        String coverUrl,
        String phone,
        BigDecimal score,
        BigDecimal tasteScore,
        BigDecimal envScore,
        BigDecimal serviceScore,
        BigDecimal pricePerCapita,
        String currency,
        String address,
        BigDecimal latitude,
        BigDecimal longitude,
        String businessHours,
        String summary,
        Boolean hasDeal,
        Boolean openNow,
        Integer status,
        String statusText,
        List<String> tags,
        String createdAt,
        String updatedAt
) {
}
