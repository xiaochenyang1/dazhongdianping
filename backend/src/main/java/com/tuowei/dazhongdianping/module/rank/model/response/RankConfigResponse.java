package com.tuowei.dazhongdianping.module.rank.model.response;

import java.math.BigDecimal;
import java.util.Map;

public record RankConfigResponse(
        Long id, Integer rankType, String rankTypeText, String region, Long cityId, Long categoryId,
        Integer version, Integer calcCycle, Map<String, BigDecimal> weight, Integer minReviewCount,
        BigDecimal minScore, Boolean manualIntervene, Integer status, String statusText,
        String effectiveFrom, String updatedAt
) {
}
