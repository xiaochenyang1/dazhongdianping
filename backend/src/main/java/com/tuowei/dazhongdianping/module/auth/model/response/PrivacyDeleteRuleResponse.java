package com.tuowei.dazhongdianping.module.auth.model.response;

public record PrivacyDeleteRuleResponse(
        Integer coolingOffDays,
        Boolean reverifyRequired
) {
}
