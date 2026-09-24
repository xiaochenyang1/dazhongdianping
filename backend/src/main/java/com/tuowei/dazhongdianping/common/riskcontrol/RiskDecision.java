package com.tuowei.dazhongdianping.common.riskcontrol;

import java.util.Collections;
import java.util.List;

/**
 * 一次评估的聚合决策：所有命中规则聚合后的最终动作、风险总分与命中明细。
 * 由 RiskEvaluationService 返回给挂钩点，挂钩点据 {@link #action()} 决定放行/转审/拦截。
 */
public final class RiskDecision {

    private final RiskAction action;
    private final int riskScore;
    private final List<String> hitRules;
    private final String reason;

    public RiskDecision(RiskAction action, int riskScore, List<String> hitRules, String reason) {
        this.action = action;
        this.riskScore = riskScore;
        this.hitRules = hitRules == null ? Collections.emptyList() : List.copyOf(hitRules);
        this.reason = reason == null ? "" : reason;
    }

    public static RiskDecision pass() {
        return new RiskDecision(RiskAction.PASS, 0, Collections.emptyList(), "");
    }

    public RiskAction action() {
        return action;
    }

    public int riskScore() {
        return riskScore;
    }

    public List<String> hitRules() {
        return hitRules;
    }

    public String reason() {
        return reason;
    }

    public boolean isBlocked() {
        return action == RiskAction.BLOCK;
    }

    public boolean needsReview() {
        return action == RiskAction.REVIEW;
    }

    public boolean hasHit() {
        return !hitRules.isEmpty();
    }
}
