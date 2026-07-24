package com.tuowei.dazhongdianping.module.admin.user.model.response;

public record AdminAppUserResponse(
        Long id,
        String nickname,
        String avatar,
        String email,
        String phone,
        String preferredRegion,
        Integer growthValue,
        Integer level,
        Integer points,
        Integer status,
        String statusText,
        String lastLoginAt,
        String createdAt
) {
}
