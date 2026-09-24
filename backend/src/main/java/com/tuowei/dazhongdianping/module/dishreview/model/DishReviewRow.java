package com.tuowei.dazhongdianping.module.dishreview.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class DishReviewRow {
    private Long id;
    private String region;
    private Long shopId;
    private Long dishId;
    private Long userId;
    private Integer score;
    private String content;
    private LocalDateTime createdAt;
}
