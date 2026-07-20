package com.tuowei.dazhongdianping.module.admin.rbac.model.response;

public record AdminPermissionResponse(
        Long id,
        String code,
        String name,
        String category,
        Integer type
) {
}
