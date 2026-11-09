package com.tuowei.dazhongdianping.module.admin.health.model.response;

import java.time.LocalDateTime;
import java.util.List;
import com.tuowei.dazhongdianping.module.release.model.response.ReleaseInfoResponse;

public record AdminSystemHealthResponse(
        String status,
        LocalDateTime checkedAt,
        long uptimeSeconds,
        String runtimeMode,
        String applicationVersion,
        ReleaseInfoResponse release,
        List<String> activeProfiles,
        List<AdminSystemHealthComponentResponse> components
) {
}
