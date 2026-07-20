package com.tuowei.dazhongdianping.module.admin.management.model.response;

import java.util.List;

public record AdminImportResultResponse(
        Long batchId,
        Integer total,
        Integer success,
        Integer failed,
        Integer status,
        String statusText,
        String errorFile,
        List<String> errorMessages
) {
}
