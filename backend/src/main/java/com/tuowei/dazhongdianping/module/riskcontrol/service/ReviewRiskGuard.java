package com.tuowei.dazhongdianping.module.riskcontrol.service;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskBlockedException;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskDecision;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRequestContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskScene;
import org.springframework.stereotype.Component;

/**
 * 点评提交场景的风控网关，供 review 模块调用而不直接耦合风控内部。
 * BLOCK → 抛 {@link RiskBlockedException}（403 + 本地化 messageKey）；
 * REVIEW → 返回 true，由调用方强制转人审。
 */
@Component
public class ReviewRiskGuard {

    private final RiskEvaluationService riskEvaluationService;

    public ReviewRiskGuard(RiskEvaluationService riskEvaluationService) {
        this.riskEvaluationService = riskEvaluationService;
    }

    /**
     * 评估一条待提交点评。
     *
     * @return true 表示命中人审规则、需强制进人审队列；false 表示放行
     */
    public boolean guardReviewCreation(String region, Long userId, String content) {
        String device = RiskRequestContext.deviceFingerprint();
        // 记录设备使用轨迹，使"本次"也计入设备的独立账号数
        riskEvaluationService.trackDevice(region, device, userId);

        RiskContext context = RiskContext.builder(RiskScene.REVIEW_CREATE, region)
                .userId(userId)
                .deviceFingerprint(device)
                .ip(RiskRequestContext.ip())
                .content(content)
                .build();
        RiskDecision decision = riskEvaluationService.evaluate(context);
        if (decision.isBlocked()) {
            throw new RiskBlockedException(
                    "点评被风控拦截：" + decision.reason(), "riskcontrol.review_blocked");
        }
        return decision.needsReview();
    }
}
