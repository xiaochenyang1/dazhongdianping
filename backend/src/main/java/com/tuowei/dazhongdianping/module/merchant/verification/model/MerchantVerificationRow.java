package com.tuowei.dazhongdianping.module.merchant.verification.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class MerchantVerificationRow {
    private Long id;
    private Long merchantId;
    private String region;
    private String reason;
    private String evidenceUrls;
    private Integer status;
    private String rejectReason;
    private Long auditBy;
    private Long submittedBy;
    private LocalDateTime submittedAt;
    private LocalDateTime auditedAt;
    private LocalDateTime effectiveStartAt;
    private LocalDateTime effectiveEndAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String companyName;
}
