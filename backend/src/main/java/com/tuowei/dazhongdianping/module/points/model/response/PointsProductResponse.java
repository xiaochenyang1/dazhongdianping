package com.tuowei.dazhongdianping.module.points.model.response;

public record PointsProductResponse(
        Long id,
        String region,
        String name,
        String coverImage,
        String description,
        Integer pointsPrice,
        Integer stock,
        Integer exchangeLimitPerUser,
        Integer exchangeCount,
        Integer fulfillType,
        String fulfillTypeText,
        Integer status,
        Integer sort,
        boolean soldOut,
        String createdAt,
        String updatedAt
) {
}
