package com.tuowei.dazhongdianping.module.auth.model.response;

public record UserGrowthRecordResponse(
        Long id,
        Integer type,
        String typeText,
        String action,
        String actionText,
        Long bizId,
        Integer changeAmount,
        Integer balanceAfter,
        String remark,
        String createdAt
) {
}
