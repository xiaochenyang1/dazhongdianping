package com.tuowei.dazhongdianping.module.merchant.model.response;

public record MerchantLoginResponse(
        String accessToken,
        String tokenType,
        Long merchantId,
        String account
) {
}
