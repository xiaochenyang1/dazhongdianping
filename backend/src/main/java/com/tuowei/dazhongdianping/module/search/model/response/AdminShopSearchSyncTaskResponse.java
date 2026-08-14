package com.tuowei.dazhongdianping.module.search.model.response;

import java.time.LocalDateTime;

public record AdminShopSearchSyncTaskResponse(
        Long shopId,
        String shopName,
        String region,
        String cityName,
        Long version,
        String state,
        String stateText,
        int attemptCount,
        LocalDateTime nextRetryAt,
        LocalDateTime lockedAt,
        String lastError,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
