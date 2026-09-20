package com.tuowei.dazhongdianping.module.recommendation.model.response;

import java.math.BigDecimal;

public record RecommendationWeightResponse(
        String region,
        BigDecimal affinityWeight,
        BigDecimal qualityWeight,
        BigDecimal popularityWeight,
        BigDecimal distanceWeight
) {
}
