package com.tuowei.dazhongdianping.module.admin.health.model.response;

public record AdminSystemHealthComponentResponse(
        String key,
        String status,
        String checkType,
        boolean critical,
        long latencyMillis,
        String detail
) {
}
