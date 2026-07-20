package com.tuowei.dazhongdianping.module.merchant.identity.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class MerchantApplicationRow {

    private Long id;
    private Long merchantId;
    private String merchantAccount;
    private String companyName;
    private String region;
    private String licenseUrl;
    private String legalPerson;
    private String shopPhotoUrls;
    private Integer status;
    private String rejectReason;
    private LocalDateTime submittedAt;
    private LocalDateTime auditedAt;
    private LocalDateTime updatedAt;
}
