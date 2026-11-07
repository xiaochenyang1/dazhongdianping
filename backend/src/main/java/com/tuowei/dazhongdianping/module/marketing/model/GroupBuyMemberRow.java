package com.tuowei.dazhongdianping.module.marketing.model;

import java.time.LocalDateTime;
import lombok.Data;

/** 拼团成员。status：0 待支付，1 已支付，2 已退出/已退款。 */
@Data
public class GroupBuyMemberRow {

    private Long id;
    private Long teamId;
    private Long campaignId;
    private String region;
    private Long userId;
    private Long orderId;
    private Integer status;
    private Integer remindStatus;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
