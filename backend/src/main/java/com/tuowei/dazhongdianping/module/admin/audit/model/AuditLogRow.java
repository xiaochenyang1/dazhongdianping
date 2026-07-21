package com.tuowei.dazhongdianping.module.admin.audit.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AuditLogRow {
    private Long id;
    private Long adminId;
    private String adminAccount;
    private String adminName;
    private String action;
    private String target;
    private String detail;
    private String ip;
    private LocalDateTime createdAt;
}
