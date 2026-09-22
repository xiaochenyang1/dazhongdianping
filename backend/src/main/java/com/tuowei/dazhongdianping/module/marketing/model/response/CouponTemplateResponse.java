package com.tuowei.dazhongdianping.module.marketing.model.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 优惠券模板返回体（运营端管理 + C端领券中心复用）。 */
public record CouponTemplateResponse(
        Long id,
        String region,
        String name,
        Integer type,
        String typeText,
        BigDecimal thresholdAmount,
        BigDecimal discountAmount,
        String currency,
        Long shopId,
        Integer totalQuantity,
        Integer claimedQuantity,
        Integer perUserLimit,
        Integer validDays,
        LocalDateTime claimStart,
        LocalDateTime claimEnd,
        Integer status
) {
}
