package com.tuowei.dazhongdianping.module.admin.report.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminReportRow {
    private Long id;
    private String reportType;
    private Long targetId;
    private Integer targetType;
    private Long reporterUserId;
    private String reporterUserName;
    private String reason;
    private Integer status;
    private String region;
    private String targetSummary;
    private String targetAuthorName;
    private Long targetAuthorId;
    private Integer targetAuditStatus;
    private Integer targetStatus;
    private LocalDateTime createdAt;
}
