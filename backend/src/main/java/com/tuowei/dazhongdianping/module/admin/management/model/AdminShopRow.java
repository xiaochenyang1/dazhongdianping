package com.tuowei.dazhongdianping.module.admin.management.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminShopRow {
    private Long id;
    private Long merchantId;
    private String merchantName;
    private String region;
    private Long categoryId;
    private String categoryName;
    private Long cityId;
    private String cityName;
    private Long areaId;
    private String areaName;
    private String name;
    private String coverUrl;
    private String phone;
    private BigDecimal score;
    private BigDecimal tasteScore;
    private BigDecimal envScore;
    private BigDecimal serviceScore;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String businessHours;
    private String summary;
    private Boolean hasDeal;
    private Boolean openNow;
    private Integer status;
    private Boolean isDeleted;
    private String tags;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
