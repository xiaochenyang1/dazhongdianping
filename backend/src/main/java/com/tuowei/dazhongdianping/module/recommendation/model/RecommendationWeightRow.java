package com.tuowei.dazhongdianping.module.recommendation.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class RecommendationWeightRow {
    private Long id;
    private String region;
    private BigDecimal affinityWeight;
    private BigDecimal qualityWeight;
    private BigDecimal popularityWeight;
    private BigDecimal distanceWeight;
    private LocalDateTime updatedAt;
}
