package com.tuowei.dazhongdianping.module.review.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewRow {

    private Long id;
    private Long userId;
    private Long shopId;
    private String region;
    private String shopName;
    private String userName;
    private String content;
    private BigDecimal scoreOverall;
    private BigDecimal scoreTaste;
    private BigDecimal scoreEnv;
    private BigDecimal scoreService;
    private BigDecimal cost;
    private String currency;
    private Integer likeCount;
    private Integer commentCount;
    private Integer auditStatus;
    private String auditRemark;
    private Integer status;
    private Boolean isDeleted;
    private String tags;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
