package com.tuowei.dazhongdianping.module.riskcontrol.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 更新风控规则（阈值/窗口/动作/风险分/开关）。
 */
public class RiskRuleUpdateRequest {

    /** 命中动作：1=放行记录 2=转人审 3=拦截 */
    @NotNull
    @Min(1)
    @Max(3)
    private Integer action;

    @NotNull
    @Min(0)
    private Integer threshold;

    @NotNull
    @Min(0)
    private Integer windowSeconds;

    @NotNull
    @Min(0)
    @Max(1000)
    private Integer riskScore;

    @NotNull
    private Boolean enabled;

    @Size(max = 255)
    private String remark = "";

    public Integer getAction() {
        return action;
    }

    public void setAction(Integer action) {
        this.action = action;
    }

    public Integer getThreshold() {
        return threshold;
    }

    public void setThreshold(Integer threshold) {
        this.threshold = threshold;
    }

    public Integer getWindowSeconds() {
        return windowSeconds;
    }

    public void setWindowSeconds(Integer windowSeconds) {
        this.windowSeconds = windowSeconds;
    }

    public Integer getRiskScore() {
        return riskScore;
    }

    public void setRiskScore(Integer riskScore) {
        this.riskScore = riskScore;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }
}
