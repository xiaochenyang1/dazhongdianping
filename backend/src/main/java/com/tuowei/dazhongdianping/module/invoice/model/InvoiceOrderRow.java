package com.tuowei.dazhongdianping.module.invoice.model;

import java.math.BigDecimal;
import lombok.Data;

/** 开票用的订单摘要。pay_status：0 待支付 1 已支付 2 已退款 3 部分退款。 */
@Data
public class InvoiceOrderRow {

    private Long id;
    private Long userId;
    private String region;
    private BigDecimal amount;
    private String currency;
    private Integer payStatus;
}
