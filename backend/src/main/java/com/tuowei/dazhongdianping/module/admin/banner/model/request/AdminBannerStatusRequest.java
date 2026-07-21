package com.tuowei.dazhongdianping.module.admin.banner.model.request;

import jakarta.validation.constraints.NotNull;

public record AdminBannerStatusRequest(
        @NotNull(message = "enabled 不能为空")
        Boolean enabled
) {
}
