package com.tuowei.dazhongdianping.module.experiment.service;

import com.tuowei.dazhongdianping.module.experiment.mapper.ExperimentMapper;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagRow;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagScopeRow;
import org.springframework.stereotype.Service;

/** Resolves global kill switches and campaign > shop > city rollout overrides. */
@Service
public class FeatureFlagEvaluator {

    private final ExperimentMapper mapper;

    public FeatureFlagEvaluator(ExperimentMapper mapper) {
        this.mapper = mapper;
    }

    public boolean enabled(String region, String flagKey, Long campaignId, Long shopId, Long userId) {
        FeatureFlagRow flag = mapper.selectFlagByKey(region, flagKey);
        if (flag == null || !Boolean.TRUE.equals(flag.getEnabled())) return false;
        boolean enabled = true;
        int rolloutPercent = flag.getRolloutPercent() == null ? 0 : flag.getRolloutPercent();
        FeatureFlagScopeRow scope = mapper.selectEffectiveFlagScope(flag.getId(), campaignId, shopId);
        if (scope != null) {
            enabled = Boolean.TRUE.equals(scope.getEnabled());
            rolloutPercent = scope.getRolloutPercent() == null ? 0 : scope.getRolloutPercent();
        }
        return ExperimentService.resolvedEnabled(
                enabled, rolloutPercent, flagKey, userId == null ? "anonymous" : String.valueOf(userId));
    }
}
