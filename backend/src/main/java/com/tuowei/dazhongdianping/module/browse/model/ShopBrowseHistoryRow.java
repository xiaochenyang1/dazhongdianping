package com.tuowei.dazhongdianping.module.browse.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ShopBrowseHistoryRow {
    private Long id;
    private Long userId;
    private Long shopId;
    private Long merchantId;
    private String region;
    private Integer viewCount;
    private LocalDateTime lastViewedAt;
    private LocalDateTime createdAt;
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
