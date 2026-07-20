package com.tuowei.dazhongdianping.module.favorite.model.response;

public record FavoriteResponse(
        Long id, Integer targetType, String targetTypeText, Long targetId,
        FavoriteTargetResponse target, String createdAt
) {
}
