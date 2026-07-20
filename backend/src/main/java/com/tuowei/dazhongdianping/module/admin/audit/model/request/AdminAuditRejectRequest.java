package com.tuowei.dazhongdianping.module.admin.audit.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AdminAuditRejectRequest {

    @NotBlank(message = "reason 不能为空")
    private String reason;
}
