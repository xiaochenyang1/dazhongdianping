package com.tuowei.dazhongdianping.module.auth.model.response;

public record AuthSessionResponse(
        String accessToken,
        String refreshToken,
        AuthUserResponse user
) {
}
