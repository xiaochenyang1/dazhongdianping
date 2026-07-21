package com.tuowei.dazhongdianping.module.admin.trade.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminOrderRow {
    private Long id;
    private String orderNo;
    private Long merchantId;
    private String merchantName;
    private Long shopId;
    private String shopName;
    private Long userId;
    private String userNickname;
    private String account;
    private Long dealId;
    private String dealTitle;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal amount;
    private String currency;
    private String payMethod;
    private Integer payStatus;
    private Integer status;
    private String paymentChannel;
    private String paymentChannelTxn;
    private Integer paymentStatus;
    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
    private LocalDateTime paymentCreatedAt;
    private Long refundId;
    private BigDecimal refundAmount;
    private String refundReason;
    private Integer refundStatus;
    private String refundAuditReason;
    private LocalDateTime refundAuditedAt;
    private LocalDateTime refundCreatedAt;
}
