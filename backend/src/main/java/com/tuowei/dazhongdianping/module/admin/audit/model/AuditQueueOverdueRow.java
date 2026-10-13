package com.tuowei.dazhongdianping.module.admin.audit.model;

import lombok.Data;

@Data
public class AuditQueueOverdueRow {

    private Integer bizType;
    private Long overdueCount;
}
