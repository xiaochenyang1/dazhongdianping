package com.tuowei.dazhongdianping.module.analytics.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.Data;

/** 单日浏览或成交汇总。 */
@Data
public class DayMetricRow {

    private LocalDate bizDate;
    private Long total;
    private BigDecimal amount;
}
