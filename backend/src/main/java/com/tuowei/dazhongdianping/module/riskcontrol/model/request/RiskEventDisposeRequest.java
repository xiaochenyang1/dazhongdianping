package com.tuowei.dazhongdianping.module.riskcontrol.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 处置风控事件。
 */
public class RiskEventDisposeRequest {

    /** 处置结果：1=确认风险 2=忽略(误报放行) */
    @NotNull
    @Min(1)
    @Max(2)
    private Integer disposeStatus;

    @Size(max = 255)
    private String disposeRemark = "";

    public Integer getDisposeStatus() {
        return disposeStatus;
    }

    public void setDisposeStatus(Integer disposeStatus) {
        this.disposeStatus = disposeStatus;
    }

    public String getDisposeRemark() {
        return disposeRemark;
    }

    public void setDisposeRemark(String disposeRemark) {
        this.disposeRemark = disposeRemark;
    }
}
