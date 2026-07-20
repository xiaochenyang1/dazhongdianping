package com.tuowei.dazhongdianping.module.admin.management.model.response;

import java.math.BigDecimal;

public record AdminShopSummaryResponse(
        Long id,
        Long merchantId,
        String merchantName,
        String name,
        String region,
        String categoryName,
        String cityName,
        String areaName,
        BigDecimal pricePerCapita,
        Integer status,
        String statusText,
        Boolean openNow,
        String createdAt
) {
}
