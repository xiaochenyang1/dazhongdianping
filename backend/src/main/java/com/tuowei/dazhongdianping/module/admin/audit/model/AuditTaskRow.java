package com.tuowei.dazhongdianping.module.admin.audit.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AuditTaskRow {

    private Long id;
    private Integer bizType;
    private Long bizId;
    private String region;
    private Integer machineResult;
    private Integer status;
    private Long auditorId;
    private Long claimedByAdminId;
    private String claimedByAdminName;
    private LocalDateTime claimedAt;
    private LocalDateTime claimExpiresAt;
    private Long claimRemainingSeconds;
    private String remark;
    private Long shopId;
    private String shopName;
    private String userName;
    private String reviewContent;
    private LocalDateTime createdAt;
    private Long ageSeconds;
    private LocalDateTime updatedAt;
}
