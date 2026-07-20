package com.tuowei.dazhongdianping.module.auth.model.response;

public record PrivacyOverviewResponse(
        PrivacyExportRuleResponse exportRule,
        PrivacyDeleteRuleResponse deleteRule,
        PrivacyExportTaskResponse latestExportTask,
        PrivacyDeleteTaskResponse latestDeleteTask
) {
}
