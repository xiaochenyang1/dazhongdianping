package com.tuowei.dazhongdianping.module.auth.model.response;

public record PrivacyExportRuleResponse(
        Integer dailyLimit,
        String defaultFormat,
        Integer expireHours
) {
}
