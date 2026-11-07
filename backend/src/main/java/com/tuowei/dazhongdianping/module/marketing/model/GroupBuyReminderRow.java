package com.tuowei.dazhongdianping.module.marketing.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class GroupBuyReminderRow {
    private Long memberId;
    private Long teamId;
    private Long userId;
    private String region;
    private String campaignTitle;
    private Integer memberCount;
    private Integer paidCount;
    private Integer groupSize;
    private LocalDateTime expireAt;
}
