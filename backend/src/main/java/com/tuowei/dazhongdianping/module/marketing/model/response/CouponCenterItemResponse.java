package com.tuowei.dazhongdianping.module.marketing.model.response;

import java.math.BigDecimal;

/** 领券中心一张可领取的券（含当前用户的可领状态）。 */
public record CouponCenterItemResponse(
        Long templateId,
        String name,
        Integer type,
        String typeText,
        BigDecimal thresholdAmount,
        BigDecimal discountAmount,
        String currency,
        Long shopId,
        Integer perUserLimit,
        Integer validDays,
        /** 是否已领满每人限额。 */
        boolean claimed,
        /** 是否已被抢光（有限量且已发完）。 */
        boolean soldOut,
        /** 当前用户是否可以领取。 */
        boolean claimable
) {
}
