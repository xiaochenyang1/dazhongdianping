package com.tuowei.dazhongdianping.module.merchant.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class MerchantReviewAppealRow {
    private Long id;
    private Long merchantId;
    private Long operatorId;
    private Long reviewId;
    private Long shopId;
    private String region;
    private LocalDateTime baseReviewUpdatedAt;
    private String reason;
    private String evidenceUrls;
    private Integer status;
    private String rejectReason;
    private Long auditBy;
    private LocalDateTime submittedAt;
    private LocalDateTime auditedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
