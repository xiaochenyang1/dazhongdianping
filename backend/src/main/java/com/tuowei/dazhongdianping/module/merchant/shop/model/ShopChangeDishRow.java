package com.tuowei.dazhongdianping.module.merchant.shop.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class ShopChangeDishRow {
    private Long id;
    private Long changeId;
    private String name;
    private BigDecimal price;
    private String recommendReason;
    private Integer sort;
}
