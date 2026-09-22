package com.tuowei.dazhongdianping.module.marketing.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

/** 用户已领取的营销券。核销关键字段从模板冗余，避免模板改动影响历史券。 */
@Data
public class UserCouponRow {

    private Long id;
    private Long templateId;
    private Long userId;
    private String region;
    /** 1=满减券 2=新客立减 */
    private Integer type;
    private BigDecimal thresholdAmount;
    private BigDecimal discountAmount;
    private String currency;
    private Long shopId;
    /** 1=未使用 2=已使用 3=已过期 */
    private Integer status;
    private Long usedOrderId;
    private LocalDateTime usedAt;
    private LocalDateTime expireAt;
    private LocalDateTime createdAt;
    /** 联表模板名（列表展示用）。 */
    private String templateName;
}
