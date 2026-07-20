package com.tuowei.dazhongdianping.module.browse.model.response;

import java.util.List;

public record CategoryNodeResponse(
        Long id,
        String name,
        List<CategoryNodeResponse> children
) {
}
