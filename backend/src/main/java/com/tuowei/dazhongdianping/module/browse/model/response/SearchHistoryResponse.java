package com.tuowei.dazhongdianping.module.browse.model.response;

public record SearchHistoryResponse(
        Long id,
        String keyword,
        String region,
        Integer searchType,
        String updatedAt
) {
}
