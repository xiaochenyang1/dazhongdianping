package com.tuowei.dazhongdianping.module.admin.geodata.model.response;

public record AdminCityResponse(
        Long id,
        String code,
        String name,
        Integer sortNo,
        Integer status
) {
}
