package com.tuowei.dazhongdianping.module.admin.banner.model.response;

public record AdminBannerResponse(
        Long id,
        String region,
        Long cityId,
        String cityName,
        String title,
        String subtitle,
        String imageUrl,
        String linkUrl,
        boolean enabled,
        int sortNo
) {
}
