package com.tuowei.dazhongdianping.module.admin.auth.model.response;

import java.util.List;

public record AdminLoginResponse(
        String accessToken,
        String tokenType,
        AdminProfile profile,
        List<String> permissions,
        List<String> regions
) {

    public record AdminProfile(
            Long id,
            String account,
            String name
    ) {
    }
}
