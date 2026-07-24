package com.tuowei.dazhongdianping.module.admin.sensitiveword.model.response;

public record AdminSensitiveWordResponse(
        Long id,
        String region,
        String word,
        Integer matchMode,
        boolean enabled,
        String remark
) {
}
