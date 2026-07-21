package com.tuowei.dazhongdianping.module.browse.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewRow {
    private Long id;
    private Long shopId;
    private Long userId;
    private String userName;
    private BigDecimal score;
    private String content;
    private Integer likedCount;
    private Integer commentCount;
    private String merchantReplyMerchantName;
    private String merchantReplyContent;
    private LocalDateTime merchantReplyCreatedAt;
    private LocalDateTime merchantReplyUpdatedAt;
    private LocalDateTime createdAt;
}
