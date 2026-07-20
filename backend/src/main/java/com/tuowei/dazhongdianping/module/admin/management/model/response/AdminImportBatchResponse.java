package com.tuowei.dazhongdianping.module.admin.management.model.response;

public record AdminImportBatchResponse(
        Long id,
        String fileName,
        String region,
        Integer total,
        Integer success,
        Integer failed,
        Integer status,
        String statusText,
        String errorFile,
        String createdAt
) {
}
