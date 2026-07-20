package com.tuowei.dazhongdianping.module.rank.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class RankItemRow {
    private Integer position;
    private BigDecimal rankScore;
    private String reason;
    private Long shopId;
    private String shopName;
    private String coverUrl;
    private BigDecimal score;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private String cityName;
    private String areaName;
    private Boolean hasDeal;
    private Boolean openNow;
    private String tags;
}
