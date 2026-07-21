package com.tuowei.dazhongdianping.module.browse.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class ShopDetailRow {
    private Long id;
    private Long categoryId;
    private Long cityId;
    private Long areaId;
    private Double latitude;
    private Double longitude;
    private String name;
    private String coverUrl;
    private BigDecimal score;
    private BigDecimal tasteScore;
    private BigDecimal envScore;
    private BigDecimal serviceScore;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private String phone;
    private String businessHours;
    private String summary;
    private String categoryName;
    private String cityName;
    private String areaName;
    private Boolean hasDeal;
    private Boolean openNow;
    private String tags;
}
