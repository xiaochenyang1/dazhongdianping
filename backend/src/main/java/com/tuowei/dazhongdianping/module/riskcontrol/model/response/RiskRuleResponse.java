package com.tuowei.dazhongdianping.module.riskcontrol.model.response;

/**
 * 风控规则视图（Admin 规则管理）。
 */
public record RiskRuleResponse(
        Long id,
        String region,
        String ruleCode,
        String name,
        String scene,
        int action,
        int threshold,
        int windowSeconds,
        int riskScore,
        boolean enabled,
        String remark
) {
}
