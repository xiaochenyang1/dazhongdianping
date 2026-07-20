package com.tuowei.dazhongdianping.module.trade.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.Data;

@Data
public class DealRow {

    private Long id;
    private Long shopId;
    private Long merchantId;
    private String region;
    private Integer type;
    private String title;
    private String coverImage;
    private BigDecimal price;
    private BigDecimal originalPrice;
    private String currency;
    private Integer stock;
    private Integer soldCount;
    private LocalDate validStart;
    private LocalDate validEnd;
    private String rules;
    private Integer auditStatus;
    private Integer status;
    private String shopName;
}
