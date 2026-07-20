package com.tuowei.dazhongdianping.module.community.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PostReportRequest(
        @NotBlank(message = "reason 不能为空")
        @Size(max = 200, message = "reason 不能超过 200 字")
        String reason
) {
}
