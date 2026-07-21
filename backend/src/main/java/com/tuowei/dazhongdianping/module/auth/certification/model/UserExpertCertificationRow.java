package com.tuowei.dazhongdianping.module.auth.certification.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserExpertCertificationRow {
    private Long id;
    private Long userId;
    private String region;
    private String reason;
    private Integer status;
    private String rejectReason;
    private Long auditBy;
    private LocalDateTime submittedAt;
    private LocalDateTime auditedAt;
    private LocalDateTime effectiveStartAt;
    private LocalDateTime effectiveEndAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
