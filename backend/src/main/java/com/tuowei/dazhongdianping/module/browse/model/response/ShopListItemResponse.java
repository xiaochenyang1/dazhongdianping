package com.tuowei.dazhongdianping.module.browse.model.response;

import com.tuowei.dazhongdianping.module.merchant.verification.model.response.MerchantVerificationBadgeResponse;
import java.math.BigDecimal;
import java.util.List;

public record ShopListItemResponse(
        Long id,
        Long merchantId,
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
        Double distanceMeters,
        MerchantVerificationBadgeResponse merchantCertification
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
                                List<String> tags,
                                Double distanceMeters) {
        this(id, null, name, coverUrl, score, pricePerCapita, currency, address, areaName, cityName, hasDeal, openNow, tags, distanceMeters, null);
    }

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
        this(id, null, name, coverUrl, score, pricePerCapita, currency, address, areaName, cityName, hasDeal, openNow, tags, null, null);
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
        this(id, null, name, coverUrl, score, pricePerCapita, null, address, areaName, cityName, hasDeal, openNow, tags, null, null);
    }

    public ShopListItemResponse withMerchantCertification(Long merchantId,
                                                          MerchantVerificationBadgeResponse merchantCertification) {
        return new ShopListItemResponse(
                id,
                merchantId,
                name,
                coverUrl,
                score,
                pricePerCapita,
                currency,
                address,
                areaName,
                cityName,
                hasDeal,
                openNow,
                tags,
                distanceMeters,
                merchantCertification
        );
    }
}
