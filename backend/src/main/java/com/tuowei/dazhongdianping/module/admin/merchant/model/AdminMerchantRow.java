package com.tuowei.dazhongdianping.module.admin.merchant.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminMerchantRow {

    private Long id;
    private String account;
    private String companyName;
    private String contactName;
    private String contactPhone;
    private String region;
    private Integer auditStatus;
    private Integer status;
    private Long shopCount;
    private Long operatorCount;
    private Long activeOperatorCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
