package com.tuowei.dazhongdianping.module.experiment;

import static org.assertj.core.api.Assertions.assertThat;

import com.tuowei.dazhongdianping.module.experiment.service.FeatureFlagEvaluator;
import com.tuowei.dazhongdianping.module.experiment.mapper.ExperimentMapper;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagScopeRow;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class FeatureFlagEvaluatorIntegrationTest {

    @Autowired JdbcTemplate jdbc;
    @Autowired FeatureFlagEvaluator evaluator;
    @Autowired ExperimentMapper mapper;

    @Test
    void appliesKillSwitchAndCampaignShopCityPrecedence() {
        long flagId = jdbc.queryForObject(
                "SELECT id FROM feature_flag WHERE region='CN' AND flag_key='group_buy'", Long.class);
        jdbc.update("UPDATE feature_flag SET enabled=TRUE,rollout_percent=0 WHERE id=?", flagId);
        insertScope(flagId, "city", 1L, true, 100);

        assertThat(evaluator.enabled("CN", "group_buy", 7001L, 10001L, 42L)).isTrue();

        insertScope(flagId, "shop", 10001L, false, 100);
        assertThat(evaluator.enabled("CN", "group_buy", 7001L, 10001L, 42L)).isFalse();

        insertScope(flagId, "campaign", 7001L, true, 100);
        assertThat(evaluator.enabled("CN", "group_buy", 7001L, 10001L, 42L)).isTrue();

        var flag = mapper.selectFlag(flagId, "CN");
        flag.setEnabled(false);
        mapper.updateFlag(flag);
        assertThat(evaluator.enabled("CN", "group_buy", 7001L, 10001L, 42L)).isFalse();
    }

    private void insertScope(long flagId, String type, long scopeId, boolean enabled, int percent) {
        FeatureFlagScopeRow row = new FeatureFlagScopeRow();
        row.setFeatureFlagId(flagId);
        row.setScopeType(type);
        row.setScopeId(scopeId);
        row.setEnabled(enabled);
        row.setRolloutPercent(percent);
        mapper.insertFlagScope(row);
    }

    @Test
    void userRolloutIsStableAndActuallyPartitionsSubjects() {
        boolean first = com.tuowei.dazhongdianping.module.experiment.service.ExperimentService
                .resolvedEnabled(true, 25, "group_buy", "42");
        assertThat(com.tuowei.dazhongdianping.module.experiment.service.ExperimentService
                .resolvedEnabled(true, 25, "group_buy", "42")).isEqualTo(first);
        long enabled = java.util.stream.LongStream.range(1, 1001)
                .filter(id -> com.tuowei.dazhongdianping.module.experiment.service.ExperimentService
                        .resolvedEnabled(true, 25, "group_buy", String.valueOf(id)))
                .count();
        assertThat(enabled).isBetween(180L, 320L);
    }
}
