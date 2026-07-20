package com.tuowei.dazhongdianping.module.admin.merchant.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

public record AdminMerchantAuditRequest(
        @Min(value = 1, message = "status 仅支持 1 或 2")
        @Max(value = 2, message = "status 仅支持 1 或 2")
        Integer status,
        @Size(max = 255, message = "reason 长度不能超过 255")
        String reason
) {
}
