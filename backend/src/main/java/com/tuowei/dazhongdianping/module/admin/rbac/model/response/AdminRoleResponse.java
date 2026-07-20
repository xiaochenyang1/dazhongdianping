package com.tuowei.dazhongdianping.module.admin.rbac.model.response;

import java.util.List;

public record AdminRoleResponse(
        Long id,
        String code,
        String name,
        String description,
        Integer status,
        Boolean builtIn,
        List<Long> permissionIds,
        long adminCount
) {
}
