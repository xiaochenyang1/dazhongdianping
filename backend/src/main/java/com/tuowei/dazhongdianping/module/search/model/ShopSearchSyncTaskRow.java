package com.tuowei.dazhongdianping.module.search.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ShopSearchSyncTaskRow {

    private Long shopId;
    private String shopName;
    private String region;
    private String cityName;
    private Long version;
    private Integer status;
    private Integer attemptCount;
    private LocalDateTime nextRetryAt;
    private LocalDateTime lockedAt;
    private String lastError;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
