package com.tuowei.dazhongdianping.module.admin.audit.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminAuditSlaAlertRow {

    private Long id;
    private String region;
    private Integer bizType;
    private Integer status;
    private Long pendingCount;
    private Long overdueCount;
    private LocalDateTime oldestPendingAt;
    private LocalDateTime firstOverdueAt;
    private LocalDateTime lastDetectedAt;
    private LocalDateTime resolvedAt;
    private LocalDateTime createdAt;
}
