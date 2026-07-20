package com.tuowei.dazhongdianping.module.browse.model.response;

public record BannerResponse(
        Long id,
        String title,
        String subtitle,
        String imageUrl,
        String linkUrl
) {
}
