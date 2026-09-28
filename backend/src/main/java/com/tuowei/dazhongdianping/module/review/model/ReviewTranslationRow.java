package com.tuowei.dazhongdianping.module.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewTranslationRow {
    private Long id;
    private Long reviewId;
    private String region;
    private Long userId;
    private String targetLang;
    private String content;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
