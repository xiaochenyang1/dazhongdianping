package com.tuowei.dazhongdianping.module.merchant.model.response;

import java.util.List;

public record MerchantRoleResponse(
        Long id,
        String code,
        String name,
        List<String> permissions
) {
}
