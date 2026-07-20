package com.tuowei.dazhongdianping.module.merchant.model.response;

import java.util.List;

public record MerchantAccountResponse(
        MerchantProfileResponse merchant,
        MerchantOperatorResponse operator,
        List<String> permissions
) {
}
