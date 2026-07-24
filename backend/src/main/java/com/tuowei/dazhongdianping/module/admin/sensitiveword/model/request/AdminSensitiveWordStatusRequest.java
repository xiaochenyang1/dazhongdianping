package com.tuowei.dazhongdianping.module.admin.sensitiveword.model.request;

import jakarta.validation.constraints.NotNull;

public record AdminSensitiveWordStatusRequest(
        @NotNull(message = "enabled 不能为空")
        Boolean enabled
) {
}
