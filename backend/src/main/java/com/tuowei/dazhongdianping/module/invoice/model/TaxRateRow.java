package com.tuowei.dazhongdianping.module.invoice.model;

import lombok.Data;

/** 区域税率。rate_bp 为万分比，600 = 6%。status：1 启用 0 停用。 */
@Data
public class TaxRateRow {

    private Long id;
    private String region;
    private String name;
    private Integer rateBp;
    private Integer status;
}
