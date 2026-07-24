package com.tuowei.dazhongdianping.module.admin.report.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminReportResolveRequest(
        @NotBlank(message = "action 不能为空")
        String action,
        @Size(max = 255, message = "remark 不能超过 255 字")
        String remark
) {
}
