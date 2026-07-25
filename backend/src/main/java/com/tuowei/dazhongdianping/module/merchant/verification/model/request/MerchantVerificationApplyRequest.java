package com.tuowei.dazhongdianping.module.merchant.verification.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.ArrayList;
import java.util.List;

public class MerchantVerificationApplyRequest {

    @NotBlank(message = "reason 不能为空")
    @Size(max = 500, message = "reason 最多 500 字")
    private String reason;

    @Size(max = 5, message = "evidenceUrls 最多 5 个")
    private List<@Size(max = 255, message = "evidenceUrl 最多 255 字") String> evidenceUrls = new ArrayList<>();

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public List<String> getEvidenceUrls() {
        return evidenceUrls;
    }

    public void setEvidenceUrls(List<String> evidenceUrls) {
        this.evidenceUrls = evidenceUrls == null ? new ArrayList<>() : evidenceUrls;
    }
}
