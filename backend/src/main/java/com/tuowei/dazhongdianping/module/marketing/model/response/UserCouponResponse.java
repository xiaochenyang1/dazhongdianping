package com.tuowei.dazhongdianping.module.marketing.model.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 用户钱包里的一张营销券。 */
public record UserCouponResponse(
        Long id,
        Long templateId,
        String name,
        Integer type,
        String typeText,
        BigDecimal thresholdAmount,
        BigDecimal discountAmount,
        String currency,
        Long shopId,
        Integer status,
        String statusText,
        LocalDateTime expireAt,
        LocalDateTime usedAt
) {
}
