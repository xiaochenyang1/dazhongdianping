package com.tuowei.dazhongdianping.module.admin.auth.model.response;

import java.util.List;

public record AdminMenuResponse(
        String code,
        String name,
        String path,
        List<AdminMenuResponse> children
) {
}
