package com.tuowei.dazhongdianping.module.auth.model.response;

public record AuthCurrentUserResponse(
        Long id,
        String nickname,
        String avatar,
        String email,
        String phone,
        Boolean hasPassword,
        Integer gender,
        String signature,
        String preferredRegion,
        Integer level,
        Integer points,
        Integer growthValue,
        UserExpertCertificationStatusResponse expertCertification
) {
}
