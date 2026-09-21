package com.tuowei.dazhongdianping.common.riskcontrol.rule;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleConfig;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleHit;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import org.springframework.stereotype.Component;

/**
 * 用户高频行为规则：同一用户在窗口内的行为次数达到阈值即命中。
 * 覆盖 review_freq / order_freq 两个规则编码（同一判定逻辑，配置不同）。
 */
@Component
public class UserFrequencyRiskRule implements RiskRule {

    @Override
    public String code() {
        return "review_freq";
    }

    @Override
    public java.util.List<String> codes() {
        // review_freq 与 order_freq 共用同一高频判定逻辑
        return java.util.List.of("review_freq", "order_freq");
    }

    @Override
    public RiskRuleHit evaluate(RiskContext context, RiskRuleConfig config, RiskSignalSource signals) {
        if (context.userId() == null || config.threshold() <= 0) {
            return RiskRuleHit.miss();
        }
        int count = signals.countUserActions(
                context.region(), context.userId(), context.scene(), config.windowSeconds());
        // count 为窗口内既有次数，加上当前这次后达到阈值即命中
        if (count + 1 >= config.threshold()) {
            return RiskRuleHit.hit(config,
                    "用户窗口内行为次数 " + (count + 1) + " 达到阈值 " + config.threshold());
        }
        return RiskRuleHit.miss();
    }
}
