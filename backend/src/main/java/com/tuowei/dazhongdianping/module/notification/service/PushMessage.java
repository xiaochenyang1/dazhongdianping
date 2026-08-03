package com.tuowei.dazhongdianping.module.notification.service;

import java.util.Map;

public record PushMessage(
        Long notificationId,
        String type,
        String title,
        String content,
        String linkUrl,
        String region
) {

    public Map<String, String> data() {
        return Map.of(
                "notificationId", String.valueOf(notificationId),
                "type", valueOrEmpty(type),
                "linkUrl", valueOrEmpty(linkUrl),
                "region", valueOrEmpty(region)
        );
    }

    private static String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }
}
