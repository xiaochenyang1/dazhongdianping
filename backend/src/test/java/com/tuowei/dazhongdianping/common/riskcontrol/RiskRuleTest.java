package com.tuowei.dazhongdianping.common.riskcontrol;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tuowei.dazhongdianping.common.riskcontrol.rule.DeviceMultiAccountRiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.rule.DuplicateContentRiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.rule.UserFrequencyRiskRule;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * 风控规则纯单测：用手写 Fake 信号源覆盖命中/未命中，规则实现无 Spring 依赖。
 */
class RiskRuleTest {

    @Test
    void userFrequencyHitsWhenWindowCountReachesThreshold() {
        UserFrequencyRiskRule rule = new UserFrequencyRiskRule();
        RiskRuleConfig config = new RiskRuleConfig(
                "review_freq", "点评高频", RiskScene.REVIEW_CREATE, RiskAction.REVIEW, 5, 3600, 40);
        RiskContext context = RiskContext.builder(RiskScene.REVIEW_CREATE, "CN").userId(1L).build();

        // 窗口内已有 4 条 + 本次 = 5，达阈值
        FakeSignals signals = new FakeSignals();
        signals.userActionCount = 4;
        assertTrue(rule.evaluate(context, config, signals).isHit());

        // 窗口内 3 条 + 本次 = 4，未达
        signals.userActionCount = 3;
        assertFalse(rule.evaluate(context, config, signals).isHit());
    }

    @Test
    void userFrequencyCoversOrderFreqCode() {
        UserFrequencyRiskRule rule = new UserFrequencyRiskRule();
        assertTrue(rule.codes().contains("order_freq"));
        assertTrue(rule.codes().contains("review_freq"));
    }

    @Test
    void deviceMultiAccountHitsOnUserCountAndBlockedDevice() {
        DeviceMultiAccountRiskRule rule = new DeviceMultiAccountRiskRule();
        RiskRuleConfig config = new RiskRuleConfig(
                "device_multi_account", "设备多账号", RiskScene.REVIEW_CREATE, RiskAction.REVIEW, 5, 0, 50);
        RiskContext context = RiskContext.builder(RiskScene.REVIEW_CREATE, "CN")
                .userId(1L).deviceFingerprint("dev-1").build();

        FakeSignals signals = new FakeSignals();
        signals.deviceUserCount = 6;
        assertTrue(rule.evaluate(context, config, signals).isHit());

        signals.deviceUserCount = 2;
        assertFalse(rule.evaluate(context, config, signals).isHit());

        signals.deviceUserCount = 0;
        signals.deviceBlocked = true;
        assertTrue(rule.evaluate(context, config, signals).isHit());
    }

    @Test
    void duplicateContentHitsOnIdenticalHistory() {
        DuplicateContentRiskRule rule = new DuplicateContentRiskRule();
        RiskRuleConfig config = new RiskRuleConfig(
                "review_duplicate", "相似点评", RiskScene.REVIEW_CREATE, RiskAction.BLOCK, 85, 0, 60);
        RiskContext context = RiskContext.builder(RiskScene.REVIEW_CREATE, "CN")
                .userId(1L).content("这家火锅非常好吃服务也很棒推荐大家来").build();

        FakeSignals signals = new FakeSignals();
        signals.recentContents = List.of("这家火锅非常好吃服务也很棒推荐大家来");
        RiskRuleHit hit = rule.evaluate(context, config, signals);
        assertTrue(hit.isHit());
        assertEquals(RiskAction.BLOCK, hit.action());

        signals.recentContents = List.of("完全不同的一段文字内容毫不相关");
        assertFalse(rule.evaluate(context, config, signals).isHit());
    }

    /** 手写 Fake 信号源。 */
    private static final class FakeSignals implements RiskSignalSource {
        int userActionCount;
        int deviceUserCount;
        boolean deviceBlocked;
        List<String> recentContents = List.of();

        @Override
        public int countUserActions(String region, Long userId, RiskScene scene, int windowSeconds) {
            return userActionCount;
        }

        @Override
        public int countDeviceUsers(String region, String fingerprint) {
            return deviceUserCount;
        }

        @Override
        public boolean isDeviceBlocked(String region, String fingerprint) {
            return deviceBlocked;
        }

        @Override
        public List<String> recentUserContents(String region, Long userId, RiskScene scene, int limit) {
            return recentContents;
        }
    }
}
