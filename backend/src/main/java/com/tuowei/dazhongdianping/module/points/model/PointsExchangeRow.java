package com.tuowei.dazhongdianping.module.points.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PointsExchangeRow {

    private Long id;
    private Long userId;
    private Long productId;
    private String productName;
    private String region;
    private Integer pointsCost;
    private Integer quantity;
    /** 0=待发放 1=已发放 2=已取消(积分已退回)。 */
    private Integer status;
    private String redeemCode;
    private String remark;
    private LocalDateTime fulfilledAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String userNickname;
}
