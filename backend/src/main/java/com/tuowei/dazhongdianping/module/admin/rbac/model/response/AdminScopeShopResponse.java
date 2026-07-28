package com.tuowei.dazhongdianping.module.admin.rbac.model.response;

public record AdminScopeShopResponse(
        Long id,
        String region,
        Long cityId,
        String cityName,
        String name
) {
}
