package com.tuowei.dazhongdianping.module.adpromo.model;

import java.math.BigDecimal;
import lombok.Data;

/** 商家广告报表行：投放花费加上点击日志汇总。 */
@Data
public class AdReportRow {

    private Long id;
    private Long shopId;
    private String name;
    private Integer status;
    private Integer auditStatus;
    private BigDecimal totalSpent;
    private BigDecimal spentToday;
    private Long clickCount;
    private BigDecimal clickCost;
}
