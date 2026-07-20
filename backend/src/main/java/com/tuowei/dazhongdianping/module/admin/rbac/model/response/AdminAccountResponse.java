package com.tuowei.dazhongdianping.module.admin.rbac.model.response;

import java.util.List;

public record AdminAccountResponse(
        Long id,
        String account,
        String name,
        Integer status,
        List<Long> roleIds,
        List<String> roleNames,
        List<String> regions,
        String lastLoginAt
) {
}
