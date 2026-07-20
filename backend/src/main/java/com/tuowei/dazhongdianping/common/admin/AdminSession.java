package com.tuowei.dazhongdianping.common.admin;

import java.util.Set;

public record AdminSession(
        Long adminId,
        String account,
        String name,
        Set<String> permissions,
        Set<String> regions
) {
}
