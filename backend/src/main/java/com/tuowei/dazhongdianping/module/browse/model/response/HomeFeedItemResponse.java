package com.tuowei.dazhongdianping.module.browse.model.response;

public record HomeFeedItemResponse(
        Long id,
        String type,
        String title,
        String subtitle,
        String coverUrl,
        Long shopId
) {
}
