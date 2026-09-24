package com.tuowei.dazhongdianping.module.recommendation.model;

import java.math.BigDecimal;
import lombok.Data;

/**
 * 推荐候选店铺原始行：店铺基础字段 + 近期浏览热度，供打分与出参映射复用。
 */
@Data
public class CandidateShopRow {
    private Long id;
    private Long merchantId;
    private Long categoryId;
    private String name;
    private String coverUrl;
    private BigDecimal score;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private Double latitude;
    private Double longitude;
    private String areaName;
    private String cityName;
    private Boolean hasDeal;
    private Boolean openNow;
    private String tags;
    private Long viewCount;
}
