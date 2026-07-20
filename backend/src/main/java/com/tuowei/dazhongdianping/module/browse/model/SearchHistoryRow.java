package com.tuowei.dazhongdianping.module.browse.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class SearchHistoryRow {
    private Long id;
    private Long userId;
    private String region;
    private String keyword;
    private Integer searchType;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
