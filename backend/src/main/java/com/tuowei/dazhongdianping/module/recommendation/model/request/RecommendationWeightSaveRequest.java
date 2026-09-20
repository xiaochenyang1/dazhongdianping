package com.tuowei.dazhongdianping.module.recommendation.model.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Admin 保存某区域的推荐打分权重。四项权重各自 0-100。
 */
public record RecommendationWeightSaveRequest(
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") BigDecimal affinityWeight,
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") BigDecimal qualityWeight,
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") BigDecimal popularityWeight,
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") BigDecimal distanceWeight
) {
}
