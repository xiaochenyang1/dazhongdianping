package com.tuowei.dazhongdianping.module.rank.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class RankCandidateRow {
    private Long shopId;
    private String shopName;
    private BigDecimal score;
    private Integer reviewCount;
    private Boolean hasDeal;
    private Boolean openNow;
}
