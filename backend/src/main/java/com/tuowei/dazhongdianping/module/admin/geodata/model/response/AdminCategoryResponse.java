package com.tuowei.dazhongdianping.module.admin.geodata.model.response;

public record AdminCategoryResponse(
        Long id,
        Long parentId,
        String name,
        Integer sortNo,
        Integer status
) {
}
