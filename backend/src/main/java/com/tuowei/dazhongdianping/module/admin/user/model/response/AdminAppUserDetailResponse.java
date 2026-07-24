package com.tuowei.dazhongdianping.module.admin.user.model.response;

public record AdminAppUserDetailResponse(
        Long id,
        String nickname,
        String avatar,
        String email,
        String phone,
        Integer gender,
        String signature,
        String preferredRegion,
        Integer growthValue,
        Integer level,
        Integer points,
        Integer status,
        String statusText,
        String lastLoginAt,
        String createdAt,
        long reviewCount,
        long postCount,
        long orderCount,
        long reservationCount,
        long favoriteCount,
        long activeSessionCount,
        String banReason,
        long pendingAppealCount,
        String latestAppealStatusText
) {
}
