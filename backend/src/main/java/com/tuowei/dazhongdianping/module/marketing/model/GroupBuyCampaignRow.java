package com.tuowei.dazhongdianping.module.marketing.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

/** 拼团活动。audit_status：1 待审核 2 已通过 3 已驳回。 */
@Data
public class GroupBuyCampaignRow {

    private Long id;
    private String region;
    private Long shopId;
    private Long merchantId;
    private Long dealId;
    private String title;
    private BigDecimal groupPrice;
    private String currency;
    private Integer groupSize;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private Integer status;
    private Integer auditStatus;
    private String rejectReason;
}
