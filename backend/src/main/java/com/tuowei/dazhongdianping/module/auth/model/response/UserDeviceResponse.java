package com.tuowei.dazhongdianping.module.auth.model.response;

public record UserDeviceResponse(
        Long id,
        String deviceUid,
        Integer platform,
        Integer pushChannel,
        boolean pushTokenSet,
        String appVersion,
        Integer status,
        String lastActiveAt,
        String createdAt,
        String updatedAt
) {
}
