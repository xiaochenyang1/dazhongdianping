package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 风控场景枚举。与 risk_rule.scene 列一一对应。
 * 放在 common.riskcontrol 而非 module 包下，遵循 SPI 铁律
 * （@MapperScan("...module") 会把 module 下所有接口当 MyBatis Mapper 代理）。
 */
public enum RiskScene {
    /** 提交点评（反虚假点评核心场景） */
    REVIEW_CREATE("review_create"),
    /** 下单（反刷单） */
    TRADE_ORDER("trade_order"),
    /** 注册（反批量养号） */
    AUTH_REGISTER("auth_register");

    private final String code;

    RiskScene(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }
}
