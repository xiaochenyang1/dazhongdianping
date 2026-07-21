package com.tuowei.dazhongdianping.module.admin.privacy.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminPrivacyTaskRow {
    private Long id;
    private Integer taskType;
    private Long userId;
    private String userNickname;
    private String account;
    private Integer status;
    private String scopeJson;
    private String format;
    private String fileName;
    private String failReason;
    private String verifyType;
    private String reason;
    private LocalDateTime expireAt;
    private LocalDateTime coolingOffExpireAt;
    private LocalDateTime completedAt;
    private LocalDateTime cancelledAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
