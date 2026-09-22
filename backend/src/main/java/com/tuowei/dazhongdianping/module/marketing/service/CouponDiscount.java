package com.tuowei.dazhongdianping.module.marketing.service;

import java.math.BigDecimal;

/** 用券结果：命中的用户券 id 与实际抵扣金额（不会超过订单金额）。 */
public record CouponDiscount(Long userCouponId, BigDecimal discountAmount) {

    public static CouponDiscount none() {
        return new CouponDiscount(null, BigDecimal.ZERO);
    }
}
