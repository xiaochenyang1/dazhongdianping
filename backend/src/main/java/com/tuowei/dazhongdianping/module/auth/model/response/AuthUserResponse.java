package com.tuowei.dazhongdianping.module.auth.model.response;

public record AuthUserResponse(
        Long id,
        String nickname,
        String avatar,
        String preferredRegion
) {
}
