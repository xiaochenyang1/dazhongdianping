package com.tuowei.dazhongdianping.common.riskcontrol.rule;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleConfig;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleHit;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 设备多账号规则：同一设备指纹关联的独立用户数达到阈值即命中；
 * 设备已被拉黑时直接以配置动作命中。多账号共享设备是刷单的强信号。
 */
@Component
public class DeviceMultiAccountRiskRule implements RiskRule {

    @Override
    public String code() {
        return "device_multi_account";
    }

    @Override
    public java.util.List<String> codes() {
        // 发点评与注册场景共用同一设备多账号判定逻辑
        return java.util.List.of("device_multi_account", "register_multi_account");
    }

    @Override
    public RiskRuleHit evaluate(RiskContext context, RiskRuleConfig config, RiskSignalSource signals) {
        if (!StringUtils.hasText(context.deviceFingerprint())) {
            return RiskRuleHit.miss();
        }
        if (signals.isDeviceBlocked(context.region(), context.deviceFingerprint())) {
            return RiskRuleHit.hit(config, "设备已被拉黑");
        }
        if (config.threshold() <= 0) {
            return RiskRuleHit.miss();
        }
        int userCount = signals.countDeviceUsers(context.region(), context.deviceFingerprint());
        if (userCount >= config.threshold()) {
            return RiskRuleHit.hit(config,
                    "设备关联账号数 " + userCount + " 达到阈值 " + config.threshold());
        }
        return RiskRuleHit.miss();
    }
}
