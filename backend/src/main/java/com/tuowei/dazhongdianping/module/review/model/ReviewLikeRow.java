package com.tuowei.dazhongdianping.module.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewLikeRow {

    private Long id;
    private Long reviewId;
    private Long userId;
    private LocalDateTime createdAt;
}
