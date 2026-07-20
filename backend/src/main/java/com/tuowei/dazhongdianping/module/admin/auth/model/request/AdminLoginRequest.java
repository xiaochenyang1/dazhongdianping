package com.tuowei.dazhongdianping.module.admin.auth.model.request;

import jakarta.validation.constraints.NotBlank;

public record AdminLoginRequest(
        @NotBlank(message = "account 不能为空") String account,
        @NotBlank(message = "password 不能为空") String password
) {
}
