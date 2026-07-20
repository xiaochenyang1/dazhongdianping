package com.tuowei.dazhongdianping.module.auth.model.response;

public record PolicyAcceptLogResponse(
        Long id,
        Integer policyType,
        String version,
        String locale,
        Integer source,
        String requestIp,
        String userAgent,
        String acceptedAt
) {
}
