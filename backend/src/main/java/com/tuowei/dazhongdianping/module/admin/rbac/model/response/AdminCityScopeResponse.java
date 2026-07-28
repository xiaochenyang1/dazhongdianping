package com.tuowei.dazhongdianping.module.admin.rbac.model.response;

import java.util.List;

public record AdminCityScopeResponse(
        String region,
        boolean allCities,
        List<Long> cityIds,
        List<Long> shopIds
) {
}
