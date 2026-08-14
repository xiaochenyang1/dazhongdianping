package com.tuowei.dazhongdianping.module.search.model;

import lombok.Data;

@Data
public class ShopSearchSyncOverviewRow {

    private Long totalCount;
    private Long pendingCount;
    private Long processingCount;
    private Long retryingCount;
    private Long staleCount;
    private Long readyCount;
}
