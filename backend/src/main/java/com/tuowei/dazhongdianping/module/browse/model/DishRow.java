package com.tuowei.dazhongdianping.module.browse.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class DishRow {
    private Long id;
    private Long shopId;
    private String name;
    private BigDecimal price;
    private String recommendReason;
    private Integer sortNo;
}
