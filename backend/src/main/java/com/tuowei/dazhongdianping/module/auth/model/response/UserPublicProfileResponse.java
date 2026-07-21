package com.tuowei.dazhongdianping.module.auth.model.response;

public record UserPublicProfileResponse(
        Long id,
        String nickname,
        String avatar,
        String signature,
        String preferredRegion,
        Integer level,
        Integer points,
        Integer growthValue,
        Long reviewCount,
        Long followerCount,
        Long followingCount,
        Boolean followedByCurrentUser,
        UserExpertCertificationBadgeResponse expertCertification
) {
}
