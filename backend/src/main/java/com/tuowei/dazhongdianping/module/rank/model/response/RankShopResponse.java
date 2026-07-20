package com.tuowei.dazhongdianping.module.rank.model.response;

import java.math.BigDecimal;
import java.util.List;

public record RankShopResponse(
        Long id,
        String name,
        String coverUrl,
        BigDecimal score,
        BigDecimal pricePerCapita,
        String currency,
        String address,
        String cityName,
        String areaName,
        Boolean hasDeal,
        Boolean openNow,
        List<String> tags
) {
}
