package com.tuowei.dazhongdianping.module.admin.merchant.model.response;

import java.util.List;

public record AdminMerchantOperatorResponse(
        Long id,
        Long merchantId,
        String account,
        String name,
        String phone,
        String email,
        Integer shopScopeType,
        String shopScopeText,
        List<Long> shopIds,
        List<String> roleNames,
        Integer status,
        String statusText,
        String disableReason,
        String createdAt,
        String updatedAt
) {
}
