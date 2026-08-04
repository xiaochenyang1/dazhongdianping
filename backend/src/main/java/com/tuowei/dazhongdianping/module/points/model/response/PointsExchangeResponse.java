package com.tuowei.dazhongdianping.module.points.model.response;

public record PointsExchangeResponse(
        Long id,
        Long productId,
        String productName,
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
