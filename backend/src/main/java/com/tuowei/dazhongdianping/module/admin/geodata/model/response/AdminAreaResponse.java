package com.tuowei.dazhongdianping.module.admin.geodata.model.response;

public record AdminAreaResponse(
        Long id,
        Long cityId,
        String name,
        Integer sortNo,
        Integer status
) {
}
