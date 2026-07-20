package com.tuowei.dazhongdianping.module.merchant.shop.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ShopChangeRow {
    private Long id;
    private Long merchantId;
    private Long operatorId;
    private String merchantName;
    private String region;
    private Integer changeType;
    private Long targetShopId;
    private LocalDateTime baseUpdatedAt;
    private Long categoryId;
    private Long cityId;
    private Long areaId;
    private String name;
    private String coverUrl;
    private String phone;
    private BigDecimal pricePerCapita;
    private String currency;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String businessHours;
    private String summary;
    private Boolean openNow;
    private String tags;
    private Integer status;
    private String rejectReason;
    private Long auditBy;
    private LocalDateTime submittedAt;
    private LocalDateTime auditedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
