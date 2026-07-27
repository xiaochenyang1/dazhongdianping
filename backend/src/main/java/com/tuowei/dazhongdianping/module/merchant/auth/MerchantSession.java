package com.tuowei.dazhongdianping.module.merchant.auth;

public record MerchantSession(
        Long operatorId,
        Long merchantId,
        String account,
        Integer operatorType,
        String region
) {
}
