package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 命中规则后的处置动作，与 risk_rule.action / risk_event.decision 列对应。
 * 数值越大越严格，聚合决策取所有命中规则中最严格的动作。
 */
public enum RiskAction {
    /** 放行，仅记录事件 */
    PASS(1),
    /** 转人工审核队列 */
    REVIEW(2),
    /** 直接拦截 */
    BLOCK(3);

    private final int code;

    RiskAction(int code) {
        this.code = code;
    }

    public int code() {
        return code;
    }

    public static RiskAction fromCode(int code) {
        for (RiskAction action : values()) {
            if (action.code == code) {
                return action;
            }
        }
        return PASS;
    }

    /** 取更严格的一个（用于多规则命中聚合）。 */
    public RiskAction escalate(RiskAction other) {
        return this.code >= other.code ? this : other;
    }
}
