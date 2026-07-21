package com.tuowei.dazhongdianping.module.browse.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class ShopListRow {
    private Long id;
    private Long categoryId;
    private Long cityId;
    private Long areaId;
    private Double latitude;
    private Double longitude;
    private String name;
    private String coverUrl;
    private BigDecimal score;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private String areaName;
    private String cityName;
    private String categoryName;
    private Boolean hasDeal;
    private Boolean openNow;
    private String tags;
}
