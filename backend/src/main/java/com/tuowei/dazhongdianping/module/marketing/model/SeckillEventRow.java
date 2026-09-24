package com.tuowei.dazhongdianping.module.marketing.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

/** 秒杀场次。audit_status：1 待审核 2 已通过 3 已驳回。 */
@Data
public class SeckillEventRow {

    private Long id;
    private String region;
    private Long shopId;
    private Long merchantId;
    private Long dealId;
    private String title;
    private BigDecimal seckillPrice;
    private String currency;
    private Integer stock;
    private Integer sold;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private Integer status;
    private Integer auditStatus;
    private String rejectReason;
}
