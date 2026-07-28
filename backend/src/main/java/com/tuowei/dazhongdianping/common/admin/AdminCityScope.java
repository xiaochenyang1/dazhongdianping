package com.tuowei.dazhongdianping.common.admin;

import java.util.Set;

public record AdminCityScope(
        boolean allCities,
        Set<Long> cityIds
) {
    public AdminCityScope {
        cityIds = cityIds == null ? Set.of() : Set.copyOf(cityIds);
    }

    public boolean allows(Long cityId) {
        return allCities || cityIds.contains(cityId);
    }
}
