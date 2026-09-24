package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 风控规则 SPI。每个实现是一条可插拔的判定逻辑（频率 / 设备多账号 / 相似文本 …），
 * 由 {@code code()} 与 risk_rule.rule_code 绑定。放在 common.riskcontrol 遵循 SPI 铁律
 * （避开 @MapperScan("...module") 把 module 下接口当 MyBatis Mapper 代理的启动异常）。
 */
public interface RiskRule {

    /** 规则编码，对应 risk_rule.rule_code。 */
    String code();

    /**
     * 该实现支持的全部规则编码。默认仅 {@link #code()}；
     * 当同一判定逻辑复用于多个配置（如 review_freq / order_freq）时可覆盖返回多个。
     */
    default java.util.List<String> codes() {
        return java.util.List.of(code());
    }

    /**
     * 执行判定。
     *
     * @param context 评估上下文（主体 + 业务信息）
     * @param config  该规则在当前区域的配置（阈值/窗口/动作/风险分）
     * @param signals 信号源，用于读取聚合数据
     * @return 命中结果，未命中返回 {@link RiskRuleHit#miss()}
     */
    RiskRuleHit evaluate(RiskContext context, RiskRuleConfig config, RiskSignalSource signals);
}
