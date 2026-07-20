package com.tuowei.dazhongdianping.module.trade.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class RefundRow {

    private Long id;
    private Long orderId;
    private Long couponId;
    private BigDecimal amount;
    private String reason;
    private Integer status;
    private Long auditBy;
    private String auditReason;
    private LocalDateTime auditedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
