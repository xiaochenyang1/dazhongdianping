package com.tuowei.dazhongdianping.module.auth.appeal.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserBanAppealRow {
    private Long id;
    private Long userId;
    private String region;
    private String account;
    private String reason;
    private Integer status;
    private String rejectReason;
    private Long auditBy;
    private LocalDateTime auditedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
