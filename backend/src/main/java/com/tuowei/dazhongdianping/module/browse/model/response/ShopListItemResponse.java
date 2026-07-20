package com.tuowei.dazhongdianping.module.browse.model.response;

import java.math.BigDecimal;
import java.util.List;

public record ShopListItemResponse(
        Long id,
        String name,
        String coverUrl,
        BigDecimal score,
        BigDecimal pricePerCapita,
        String currency,
        String address,
        String areaName,
        String cityName,
        Boolean hasDeal,
        Boolean openNow,
        List<String> tags,
        Double distanceMeters
) {
    public ShopListItemResponse(Long id,
                                String name,
                                String coverUrl,
                                BigDecimal score,
                                BigDecimal pricePerCapita,
                                String currency,
                                String address,
                                String areaName,
                                String cityName,
                                Boolean hasDeal,
                                Boolean openNow,
                                List<String> tags) {
        this(id, name, coverUrl, score, pricePerCapita, currency, address, areaName, cityName, hasDeal, openNow, tags, null);
    }

    public ShopListItemResponse(Long id,
                                String name,
                                String coverUrl,
                                BigDecimal score,
                                BigDecimal pricePerCapita,
                                String address,
                                String areaName,
                                String cityName,
                                Boolean hasDeal,
                                Boolean openNow,
                                List<String> tags) {
        this(id, name, coverUrl, score, pricePerCapita, null, address, areaName, cityName, hasDeal, openNow, tags, null);
    }
}
