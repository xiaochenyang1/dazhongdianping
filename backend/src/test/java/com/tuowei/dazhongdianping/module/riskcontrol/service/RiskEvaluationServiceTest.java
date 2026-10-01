package com.tuowei.dazhongdianping.module.riskcontrol.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskAction;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskDecision;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleHit;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskScene;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import com.tuowei.dazhongdianping.module.riskcontrol.mapper.RiskMapper;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskRuleRow;
import java.util.List;
import org.junit.jupiter.api.Test;

class RiskEvaluationServiceTest {

    private static final String RULE_CODE = "test_block_rule";

    private final RiskMapper riskMapper = mock(RiskMapper.class);
    private final RiskSignalSource signalSource = mock(RiskSignalSource.class);
    private final RiskEventRecorder eventRecorder = mock(RiskEventRecorder.class);

    private final RiskRule alwaysHit = new RiskRule() {
        @Override
        public String code() {
            return RULE_CODE;
        }

        @Override
        public RiskRuleHit evaluate(RiskContext context,
                                    com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleConfig config,
                                    RiskSignalSource signals) {
            return RiskRuleHit.hit(config, "命中");
        }
    };

    private RiskEvaluationService service() {
        return new RiskEvaluationService(riskMapper, signalSource, eventRecorder, List.of(alwaysHit));
    }

    private RiskContext context() {
        return RiskContext.builder(RiskScene.TRADE_ORDER, "CN")
                .userId(1L)
                .deviceFingerprint("fp-1")
                .build();
    }

    private void givenRule(RiskAction action) {
        RiskRuleRow row = new RiskRuleRow();
        row.setRuleCode(RULE_CODE);
        row.setName("测试规则");
        row.setAction(action.code());
        row.setRiskScore(80);
        when(riskMapper.selectEnabledRules("CN", RiskScene.TRADE_ORDER.code())).thenReturn(List.of(row));
    }

    @Test
    void shouldKeepBlockDecisionWhenAuditPersistFails() {
        givenRule(RiskAction.BLOCK);
        doThrow(new IllegalStateException("risk_event insert failed"))
                .when(eventRecorder).record(any(RiskEventRow.class));

        RiskDecision decision = service().evaluate(context());

        assertThat(decision.action()).isEqualTo(RiskAction.BLOCK);
        assertThat(decision.hitRules()).containsExactly(RULE_CODE);
    }

    @Test
    void shouldKeepReviewDecisionWhenDeviceCounterFails() {
        givenRule(RiskAction.REVIEW);
        doThrow(new IllegalStateException("deadlock"))
                .when(riskMapper).incrementDeviceRiskHit(anyString(), anyString());

        RiskDecision decision = service().evaluate(context());

        assertThat(decision.action()).isEqualTo(RiskAction.REVIEW);
        verify(eventRecorder).record(any(RiskEventRow.class));
    }

    @Test
    void shouldPassWhenRuleLoadingFails() {
        when(riskMapper.selectEnabledRules(anyString(), anyString()))
                .thenThrow(new IllegalStateException("db down"));

        RiskDecision decision = service().evaluate(context());

        assertThat(decision.action()).isEqualTo(RiskAction.PASS);
        verify(eventRecorder, never()).record(any(RiskEventRow.class));
    }
}
