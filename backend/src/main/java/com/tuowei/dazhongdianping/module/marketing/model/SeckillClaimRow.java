package com.tuowei.dazhongdianping.module.marketing.model;

import lombok.Data;

/** 每人每场一条：0 历史参与，1 待支付，2 已支付，3 已释放，4 已退款（仍占限购次数）。 */
@Data
public class SeckillClaimRow {

    private Long id;
    private Long eventId;
    private Long userId;
    private String region;
    private Long orderId;
    private Integer status;
}
