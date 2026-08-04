package com.tuowei.dazhongdianping.module.admin.merchant.model.response;

public record AdminMerchantOperationLogResponse(
        Long id,
        Long merchantId,
        Long operatorId,
        String operatorAccount,
        String operatorName,
        String action,
        String targetType,
        Long targetId,
        String detail,
        String createdAt
) {
}
