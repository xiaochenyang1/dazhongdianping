package com.tuowei.dazhongdianping.module.favorite.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class FavoriteRow {
    private Long id;
    private Long userId;
    private Integer targetType;
    private Long targetId;
    private LocalDateTime createdAt;
    private String targetName;
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
