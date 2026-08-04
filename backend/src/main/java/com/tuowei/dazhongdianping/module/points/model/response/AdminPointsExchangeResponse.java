package com.tuowei.dazhongdianping.module.points.model.response;

public record AdminPointsExchangeResponse(
        Long id,
        Long userId,
        String userNickname,
        Long productId,
        String productName,
        String region,
        Integer pointsCost,
        Integer quantity,
        Integer status,
        String statusText,
        String redeemCode,
        String remark,
        String fulfilledAt,
        String createdAt
) {
}
