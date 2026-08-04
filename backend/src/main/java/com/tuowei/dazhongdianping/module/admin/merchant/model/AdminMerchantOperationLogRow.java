package com.tuowei.dazhongdianping.module.admin.merchant.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminMerchantOperationLogRow {

    private Long id;
    private Long merchantId;
    private Long operatorId;
    private String operatorAccount;
    private String operatorName;
    private String action;
    private String targetType;
    private Long targetId;
    private String detail;
    private LocalDateTime createdAt;
}
