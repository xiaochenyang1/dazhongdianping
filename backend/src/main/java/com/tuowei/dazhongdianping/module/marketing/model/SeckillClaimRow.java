package com.tuowei.dazhongdianping.module.marketing.model;

import lombok.Data;

/** 秒杀领取记录，同一用户同一场次只能一条。 */
@Data
public class SeckillClaimRow {

    private Long id;
    private Long eventId;
    private Long userId;
    private String region;
}
