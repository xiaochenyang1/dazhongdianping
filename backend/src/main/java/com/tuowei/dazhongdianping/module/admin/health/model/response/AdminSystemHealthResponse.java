package com.tuowei.dazhongdianping.module.admin.health.model.response;

import java.time.LocalDateTime;
import java.util.List;

public record AdminSystemHealthResponse(
        String status,
        LocalDateTime checkedAt,
        long uptimeSeconds,
        String runtimeMode,
        String applicationVersion,
        List<String> activeProfiles,
        List<AdminSystemHealthComponentResponse> components
) {
}
