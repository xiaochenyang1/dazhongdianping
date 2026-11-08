package com.tuowei.dazhongdianping.module.admin.groupbuy.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminGroupBuyTeamRow {
    private Long id;
    private Long campaignId;
    private String campaignTitle;
    private Long shopId;
    private String shopName;
    private Long cityId;
    private String region;
    private Integer status;
    private Integer memberCount;
    private Integer paidCount;
    private Integer groupSize;
    private Long memberOrders;
    private Long paidOrders;
    private Long pendingRefunds;
    private Long failedRefunds;
    private Long missingCouponOrders;
    private Long unreleasedInventoryOrders;
    private LocalDateTime expireAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
