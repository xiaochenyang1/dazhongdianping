package com.tuowei.dazhongdianping.module.admin.trade.model.response;

public record AdminChannelStatementBatchResponse(
        Long id,
        String channel,
        String fileName,
        String fileSha256,
        Integer totalRows,
        Integer matchedRows,
        Integer discrepancyRows,
        Integer unmatchedRows,
        Integer invalidRows,
        Integer ignoredRows,
        Integer status,
        String statusText,
        String createdAt
) {
}
