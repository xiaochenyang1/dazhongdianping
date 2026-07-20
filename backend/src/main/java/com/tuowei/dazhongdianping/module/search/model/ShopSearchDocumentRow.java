package com.tuowei.dazhongdianping.module.search.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class ShopSearchDocumentRow {
    private Long id;
    private String region;
    private String name;
    private Long categoryId;
    private String categoryName;
    private Long cityId;
    private String cityName;
    private Long areaId;
    private String areaName;
    private Double latitude;
    private Double longitude;
    private String coverUrl;
    private BigDecimal score;
    private Integer reviewCount;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private Boolean hasDeal;
    private Boolean openNow;
    private Integer status;
    private String tags;
}
