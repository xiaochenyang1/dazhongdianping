package com.tuowei.dazhongdianping.module.marketing.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

/** 领券中心的优惠券模板（平台/运营配置），按区域隔离。 */
@Data
public class CouponTemplateRow {

    private Long id;
    private String region;
    private String name;
    /** 1=满减券 2=新客立减 */
    private Integer type;
    private BigDecimal thresholdAmount;
    private BigDecimal discountAmount;
    private String currency;
    /** 0=全平台通用，否则限定商户 */
    private Long shopId;
    /** 0=不限量 */
    private Integer totalQuantity;
    private Integer claimedQuantity;
    private Integer perUserLimit;
    private Integer validDays;
    private LocalDateTime claimStart;
    private LocalDateTime claimEnd;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean isDeleted;
}
