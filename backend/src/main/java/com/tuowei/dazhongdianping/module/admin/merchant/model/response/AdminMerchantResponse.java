package com.tuowei.dazhongdianping.module.admin.merchant.model.response;

public record AdminMerchantResponse(
        Long id,
        String account,
        String companyName,
        String contactName,
        String contactPhone,
        String region,
        Integer auditStatus,
        String auditStatusText,
        Integer status,
        String statusText,
        long shopCount,
        long operatorCount,
        long activeOperatorCount,
        String disableReason,
        String createdAt,
        String updatedAt
) {
}
