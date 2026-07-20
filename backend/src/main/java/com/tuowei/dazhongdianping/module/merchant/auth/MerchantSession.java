package com.tuowei.dazhongdianping.module.merchant.auth;

public record MerchantSession(
        Long operatorId,
        Long merchantId,
        String account,
        Integer operatorType
) {

    public MerchantSession(Long merchantId, String account) {
        this(merchantId, merchantId, account, 1);
    }
}
