package com.tuowei.dazhongdianping.module.admin.auth.model.response;

import java.util.List;

public record AdminMeResponse(
        AdminLoginResponse.AdminProfile profile,
        List<String> permissions,
        List<String> regions
) {
}
