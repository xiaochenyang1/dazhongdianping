package com.tuowei.dazhongdianping.module.rank.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class RankConfigRow {
    private Long id;
    private Integer rankType;
    private String region;
    private Long cityId;
    private Long categoryId;
    private Integer version;
    private Integer calcCycle;
    private String weightJson;
    private Integer minReviewCount;
    private BigDecimal minScore;
    private Boolean manualIntervene;
    private Integer status;
    private LocalDateTime effectiveFrom;
    private LocalDateTime effectiveTo;
    private Long updatedBy;
    private LocalDateTime updatedAt;
}
