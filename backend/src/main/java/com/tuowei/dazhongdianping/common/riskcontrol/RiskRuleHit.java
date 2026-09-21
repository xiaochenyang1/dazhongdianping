package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 规则命中结果。未命中返回 {@link #miss()}，命中返回携带动作/风险分/原因的实例。
 */
public final class RiskRuleHit {

    private static final RiskRuleHit MISS = new RiskRuleHit(false, null, null, 0, "");

    private final boolean hit;
    private final String ruleCode;
    private final RiskAction action;
    private final int riskScore;
    private final String reason;

    private RiskRuleHit(boolean hit, String ruleCode, RiskAction action, int riskScore, String reason) {
        this.hit = hit;
        this.ruleCode = ruleCode;
        this.action = action;
        this.riskScore = riskScore;
        this.reason = reason;
    }

    public static RiskRuleHit miss() {
        return MISS;
    }

    public static RiskRuleHit hit(RiskRuleConfig config, String reason) {
        return new RiskRuleHit(true, config.ruleCode(), config.action(), config.riskScore(), reason);
    }

    public boolean isHit() {
        return hit;
    }

    public String ruleCode() {
        return ruleCode;
    }

    public RiskAction action() {
        return action;
    }

    public int riskScore() {
        return riskScore;
    }

    public String reason() {
        return reason;
    }
}
