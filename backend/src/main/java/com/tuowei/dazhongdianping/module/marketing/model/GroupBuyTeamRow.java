package com.tuowei.dazhongdianping.module.marketing.model;

import java.time.LocalDateTime;
import lombok.Data;

/** 拼团团。status：1 拼团中，2 已成团，3 已过期。 */
@Data
public class GroupBuyTeamRow {

    private Long id;
    private Long campaignId;
    private String region;
    private Long leaderUserId;
    private Integer status;
    private Integer memberCount;
    private Integer paidCount;
    private Integer groupSize;
    private LocalDateTime expireAt;
}
