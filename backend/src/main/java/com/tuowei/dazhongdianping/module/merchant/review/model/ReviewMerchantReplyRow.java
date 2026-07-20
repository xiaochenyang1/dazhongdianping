package com.tuowei.dazhongdianping.module.merchant.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewMerchantReplyRow {
    private Long id;
    private Long reviewId;
    private Long shopId;
    private Long merchantId;
    private String merchantName;
    private Long operatorId;
    private String content;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
