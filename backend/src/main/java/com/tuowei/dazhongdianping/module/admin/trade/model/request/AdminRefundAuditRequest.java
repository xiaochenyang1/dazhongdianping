package com.tuowei.dazhongdianping.module.admin.trade.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminRefundAuditRequest(
        @NotBlank(message = "退款审核决定不能为空") String decision,
        @NotBlank(message = "退款审核原因不能为空")
        @Size(max = 255, message = "退款审核原因不能超过 255 个字符") String reason
) {
}
