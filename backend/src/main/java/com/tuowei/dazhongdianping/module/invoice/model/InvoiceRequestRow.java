package com.tuowei.dazhongdianping.module.invoice.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

/** 开票申请。status：1 待开票 2 已开票 3 已驳回。 */
@Data
public class InvoiceRequestRow {

    private Long id;
    private String region;
    private Long userId;
    private Long orderId;
    private Long titleId;
    private BigDecimal amount;
    private BigDecimal taxAmount;
    private String currency;
    private Integer status;
    private String invoiceNo;
    private String rejectReason;
    private LocalDateTime createdAt;
}
