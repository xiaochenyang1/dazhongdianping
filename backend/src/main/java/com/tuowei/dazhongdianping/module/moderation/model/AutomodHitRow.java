package com.tuowei.dazhongdianping.module.moderation.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AutomodHitRow {
    private Long id;
    private String region;
    private String bizType;
    private Long bizId;
    private Long userId;
    private Integer decision;
    private String provider;
    private String reason;
    private LocalDateTime createdAt;
}
