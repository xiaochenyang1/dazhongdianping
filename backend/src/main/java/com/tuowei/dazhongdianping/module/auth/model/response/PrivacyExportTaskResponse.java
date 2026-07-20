package com.tuowei.dazhongdianping.module.auth.model.response;

import java.util.List;

public record PrivacyExportTaskResponse(
        Long id,
        Integer status,
        String statusText,
        List<String> modules,
        String format,
        String downloadUrl,
        String expireAt,
        String failReason,
        String createdAt,
        String updatedAt
) {
}
