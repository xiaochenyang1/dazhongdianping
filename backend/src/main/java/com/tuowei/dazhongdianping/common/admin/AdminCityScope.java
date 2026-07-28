package com.tuowei.dazhongdianping.common.admin;

import java.util.Set;

public record AdminCityScope(
        boolean allCities,
        Set<Long> cityIds,
        Set<Long> shopIds
) {
    public AdminCityScope(boolean allCities, Set<Long> cityIds) {
        this(allCities, cityIds, Set.of());
    }

    public AdminCityScope {
        cityIds = cityIds == null ? Set.of() : Set.copyOf(cityIds);
        shopIds = shopIds == null ? Set.of() : Set.copyOf(shopIds);
    }

    public boolean allows(Long cityId) {
        return allCities || cityIds.contains(cityId);
    }

    public boolean allows(Long cityId, Long shopId) {
        return allCities || cityIds.contains(cityId) || shopIds.contains(shopId);
    }
}
