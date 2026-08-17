package com.tuowei.dazhongdianping.module.search.model.response;

public record AdminShopSearchSyncOverviewResponse(
        String region,
        String provider,
        String indexName,
        boolean enabled,
        long total,
        long pending,
        long processing,
        long retrying,
        long stale,
        long ready
) {
}
