package com.tuowei.dazhongdianping.module.admin.trade.model.response;

import java.math.BigDecimal;

public record AdminOrderResponse(
        Long id,
        String orderNo,
        Long merchantId,
        String merchantName,
        Long shopId,
        String shopName,
        Long userId,
        String userNickname,
        String account,
        Long dealId,
        String dealTitle,
        Integer quantity,
        BigDecimal unitPrice,
        BigDecimal amount,
        String currency,
        String payMethod,
        Integer payStatus,
        String payStatusText,
        Integer status,
        String statusText,
        String paymentChannel,
        String paymentChannelTxn,
        Integer paymentStatus,
        String paymentStatusText,
        String paidAt,
        String createdAt,
        String paymentCreatedAt,
        Long refundId,
        BigDecimal refundAmount,
        String refundReason,
        Integer refundStatus,
        String refundStatusText,
        String refundAuditReason,
        String refundAuditedAt,
        String refundCreatedAt
) {
}
