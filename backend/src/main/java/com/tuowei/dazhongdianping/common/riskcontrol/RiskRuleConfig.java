package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 单条风控规则的运行时配置，由 risk_rule 表行映射而来后传给对应 RiskRule 实现。
 * 规则实现只读配置 + 上下文 + 信号源，不直接触碰数据库（保持可测试与解耦）。
 */
public final class RiskRuleConfig {

    private final String ruleCode;
    private final String name;
    private final RiskScene scene;
    private final RiskAction action;
    private final int threshold;
    private final int windowSeconds;
    private final int riskScore;

    public RiskRuleConfig(String ruleCode, String name, RiskScene scene,
                          RiskAction action, int threshold, int windowSeconds, int riskScore) {
        this.ruleCode = ruleCode;
        this.name = name;
        this.scene = scene;
        this.action = action;
        this.threshold = threshold;
        this.windowSeconds = windowSeconds;
        this.riskScore = riskScore;
    }

    public String ruleCode() {
        return ruleCode;
    }

    public String name() {
        return name;
    }

    public RiskScene scene() {
        return scene;
    }

    public RiskAction action() {
        return action;
    }

    public int threshold() {
        return threshold;
    }

    public int windowSeconds() {
        return windowSeconds;
    }

    public int riskScore() {
        return riskScore;
    }
}
