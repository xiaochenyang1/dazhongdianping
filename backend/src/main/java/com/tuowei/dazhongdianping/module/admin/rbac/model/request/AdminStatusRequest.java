package com.tuowei.dazhongdianping.module.admin.rbac.model.request;

import jakarta.validation.constraints.NotNull;

public record AdminStatusRequest(@NotNull(message = "status 不能为空") Integer status) {
}
