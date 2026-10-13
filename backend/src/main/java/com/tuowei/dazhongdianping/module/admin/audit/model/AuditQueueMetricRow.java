package com.tuowei.dazhongdianping.module.admin.audit.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AuditQueueMetricRow {

    private Integer bizType;
    private Long pendingCount;
    private LocalDateTime oldestPendingAt;
    private Long oldestPendingAgeSeconds;
    private Long processedCount;
    private Long averageProcessingSeconds;
}
