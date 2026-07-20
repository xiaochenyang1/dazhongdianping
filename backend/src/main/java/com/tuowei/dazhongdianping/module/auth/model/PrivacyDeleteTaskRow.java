package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PrivacyDeleteTaskRow {

    private Long id;
    private Long userId;
    private String verifyType;
    private String accountSnapshot;
    private String reason;
    private Integer status;
    private LocalDateTime coolingOffExpireAt;
    private LocalDateTime completedAt;
    private LocalDateTime cancelledAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
