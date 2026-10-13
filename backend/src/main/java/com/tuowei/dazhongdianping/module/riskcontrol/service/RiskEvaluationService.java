package com.tuowei.dazhongdianping.module.riskcontrol.service;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskAction;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskDecision;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleConfig;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleHit;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskScene;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import com.tuowei.dazhongdianping.module.riskcontrol.mapper.RiskMapper;
import com.tuowei.dazhongdianping.module.riskcontrol.model.DeviceFingerprintRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskRuleRow;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 风控评估核心服务。挂钩点（点评提交 / 下单 / 注册）构造 {@link RiskContext} 调 {@link #evaluate}，
 * 服务加载该区域该场景启用的规则，逐条判定 → 聚合最严格动作与风险总分 → 落 risk_event → 返回决策。
 * 评估失败（如信号源异常）采取"放行 + 记录日志"的容错策略，避免风控自身故障阻断主流程。
 */
@Service
public class RiskEvaluationService {

    private static final Logger log = LoggerFactory.getLogger(RiskEvaluationService.class);

    private final RiskMapper riskMapper;
    private final RiskSignalSource signalSource;
    private final RiskEventRecorder eventRecorder;
    /** rule_code → RiskRule 实现（一个实现可注册多个 code）。 */
    private final Map<String, RiskRule> rulesByCode = new HashMap<>();

    public RiskEvaluationService(RiskMapper riskMapper,
                                 RiskSignalSource signalSource,
                                 RiskEventRecorder eventRecorder,
                                 List<RiskRule> rules) {
        this.riskMapper = riskMapper;
        this.signalSource = signalSource;
        this.eventRecorder = eventRecorder;
        for (RiskRule rule : rules) {
            for (String code : rule.codes()) {
                rulesByCode.put(code, rule);
            }
        }
    }

    /**
     * 执行一次风控评估并持久化命中事件。
     *
     * @return 聚合决策；调用方据 {@code action()} 决定放行 / 转人审 / 拦截
     */
    public RiskDecision evaluate(RiskContext context) {
        RiskDecision decision;
        try {
            decision = doEvaluate(context);
        } catch (RuntimeException ex) {
            // 规则加载/信号源等评估自身异常时,风控作为旁路能力降级放行并告警,不阻断主业务
            log.warn("风控评估异常，降级放行 scene={} user={}", context.scene(), context.userId(), ex);
            return RiskDecision.pass();
        }
        // 决策已定后再落审计:审计/设备计数是旁路副作用,其失败绝不能把已判定的 REVIEW/BLOCK 降级为放行
        recordDecision(context, decision);
        return decision;
    }

    private RiskDecision doEvaluate(RiskContext context) {
        List<RiskRuleRow> ruleRows =
                riskMapper.selectEnabledRules(context.region(), context.scene().code());

        RiskAction aggregated = RiskAction.PASS;
        int totalScore = 0;
        List<String> hitCodes = new ArrayList<>();
        List<String> reasons = new ArrayList<>();

        for (RiskRuleRow ruleRow : ruleRows) {
            RiskRule rule = rulesByCode.get(ruleRow.getRuleCode());
            if (rule == null) {
                continue;
            }
            RiskRuleConfig config = toConfig(ruleRow, context.scene());
            RiskRuleHit hit = rule.evaluate(context, config, signalSource);
            if (hit.isHit()) {
                aggregated = aggregated.escalate(hit.action());
                totalScore += hit.riskScore();
                hitCodes.add(hit.ruleCode());
                reasons.add(ruleRow.getName() + "：" + hit.reason());
            }
        }

        if (hitCodes.isEmpty()) {
            return RiskDecision.pass();
        }

        return new RiskDecision(aggregated, totalScore, hitCodes, String.join("；", reasons));
    }

    /**
     * 落命中审计:独立事务写 risk_event(即便主业务事务因 BLOCK 回滚仍留痕)+ 主事务内更新设备命中计数。
     * 整体 best-effort:审计侧任何异常(risk_event 结构漂移、独立事务连接耗尽、设备行死锁等)只告警,
     * 不再向上抛出,以免把 {@link #doEvaluate} 已判定的 REVIEW/BLOCK 静默降级为放行。
     */
    private void recordDecision(RiskContext context, RiskDecision decision) {
        if (!decision.hasHit()) {
            return;
        }
        try {
            persistEvent(context, decision);
            // 设备命中计数更新的是本事务刚写过的 device_fingerprint 行，须留在主事务内避免与独立事务互锁。
            if (StringUtils.hasText(context.deviceFingerprint())) {
                riskMapper.incrementDeviceRiskHit(context.region(), context.deviceFingerprint());
            }
        } catch (RuntimeException ex) {
            log.error("风控审计落库失败，但已保留 {} 决策 scene={} user={}",
                    decision.action(), context.scene(), context.userId(), ex);
        }
    }

    private void persistEvent(RiskContext context, RiskDecision decision) {
        RiskEventRow row = new RiskEventRow();
        row.setRegion(context.region());
        row.setScene(context.scene().code());
        row.setUserId(context.userId());
        row.setDeviceFingerprint(context.deviceFingerprint());
        row.setIp(context.ip());
        row.setBizId(context.bizId());
        row.setRiskScore(decision.riskScore());
        row.setDecision(decision.action().code());
        row.setHitRules(String.join(",", decision.hitRules()));
        row.setReason(truncate(decision.reason(), 512));
        row.setDisposeStatus(0);
        eventRecorder.record(row);
    }

    /**
     * 记录设备指纹使用轨迹（供多账号规则读取）。挂钩点在评估前调用，
     * 使"当前这次"也被计入设备的独立用户数。
     */
    public void trackDevice(String region, String fingerprint, Long userId) {
        if (!StringUtils.hasText(fingerprint)) {
            return;
        }
        DeviceFingerprintRow existing = riskMapper.selectDevice(region, fingerprint);
        if (existing == null) {
            riskMapper.insertDevice(region, fingerprint, userId);
        } else {
            riskMapper.updateDeviceSeen(region, fingerprint, userId);
        }
        // 记录设备-用户明细，去重后的独立账号数由 device_fingerprint_user 统计
        if (userId != null) {
            riskMapper.upsertDeviceUser(region, fingerprint, userId);
        }
    }

    private RiskRuleConfig toConfig(RiskRuleRow row, RiskScene scene) {
        return new RiskRuleConfig(
                row.getRuleCode(),
                row.getName(),
                scene,
                RiskAction.fromCode(row.getAction() == null ? 1 : row.getAction()),
                row.getThreshold() == null ? 0 : row.getThreshold(),
                row.getWindowSeconds() == null ? 0 : row.getWindowSeconds(),
                row.getRiskScore() == null ? 0 : row.getRiskScore()
        );
    }

    private String truncate(String text, int max) {
        if (text == null) {
            return "";
        }
        return text.length() <= max ? text : text.substring(0, max);
    }
}
