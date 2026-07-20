package com.tuowei.dazhongdianping.module.trade.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class OrderRow {

    private Long id;
    private String orderNo;
    private Long userId;
    private Long dealId;
    private Long shopId;
    private String region;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal amount;
    private String currency;
    private String payMethod;
    private Integer payStatus;
    private Integer status;
    private LocalDateTime paidAt;
    private LocalDateTime expireAt;
    private LocalDateTime createdAt;
    private String dealTitle;
    private String shopName;
    private String coverImage;
}
