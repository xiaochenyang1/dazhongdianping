package com.tuowei.dazhongdianping.module.admin.audit.model.response;

public record AdminAuditTaskResponse(
        Long id,
        Integer bizType,
        String bizTypeText,
        Long bizId,
        String region,
        Integer status,
        String statusText,
        Long shopId,
        String shopName,
        String submittedBy,
        String summary,
        String remark,
        String createdAt,
        String updatedAt
) {
}
