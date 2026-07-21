package com.tuowei.dazhongdianping.module.admin.hotword.model.response;

public record AdminHotWordResponse(
        Long id,
        String region,
        String keyword,
        boolean enabled,
        int sortNo
) {
}
