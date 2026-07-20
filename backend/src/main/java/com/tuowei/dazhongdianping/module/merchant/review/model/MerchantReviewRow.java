package com.tuowei.dazhongdianping.module.merchant.review.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class MerchantReviewRow {
    private Long id;
    private Long userId;
    private Long shopId;
    private String shopName;
    private Long merchantId;
    private String merchantName;
    private String region;
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
    private Integer status;
    private String tags;
    private Long replyId;
    private String replyContent;
    private Long replyOperatorId;
    private LocalDateTime replyCreatedAt;
    private LocalDateTime replyUpdatedAt;
    private Long appealId;
    private Integer appealStatus;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
