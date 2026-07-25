package com.tuowei.dazhongdianping.module.browse.model.response;

import com.tuowei.dazhongdianping.module.merchant.verification.model.response.MerchantVerificationBadgeResponse;
import java.math.BigDecimal;
import java.util.List;

public record ShopBrowseHistoryResponse(
        Long id,
        Long shopId,
        Long merchantId,
        String shopName,
        String coverUrl,
        BigDecimal score,
        BigDecimal pricePerCapita,
        String currency,
        String address,
        String cityName,
        String areaName,
        Boolean hasDeal,
        Boolean openNow,
        List<String> tags,
        Integer viewCount,
        String lastViewedAt,
        MerchantVerificationBadgeResponse merchantCertification
) {
}
