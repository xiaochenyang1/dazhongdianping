package com.tuowei.dazhongdianping.module.admin.hotword.model.request;

import jakarta.validation.constraints.NotNull;

public record AdminHotWordStatusRequest(
        @NotNull(message = "enabled 不能为空")
        Boolean enabled
) {
}
