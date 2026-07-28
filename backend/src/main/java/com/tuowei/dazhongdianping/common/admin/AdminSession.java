package com.tuowei.dazhongdianping.common.admin;

import java.util.Map;
import java.util.Set;

public record AdminSession(
        Long adminId,
        String account,
        String name,
        Set<String> permissions,
        Set<String> regions,
        Map<String, AdminCityScope> cityScopes
) {
    public AdminSession {
        permissions = permissions == null ? Set.of() : Set.copyOf(permissions);
        regions = regions == null ? Set.of() : Set.copyOf(regions);
        cityScopes = cityScopes == null ? Map.of() : Map.copyOf(cityScopes);
    }
}
