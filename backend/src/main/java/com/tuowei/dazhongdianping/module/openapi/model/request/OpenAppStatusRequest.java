package com.tuowei.dazhongdianping.module.openapi.model.request;

import jakarta.validation.constraints.NotNull;

/** 更新开放平台应用状态。1 启用，其他值停用。 */
public record OpenAppStatusRequest(
        @NotNull(message = "请选择状态") Integer status
) {
}
