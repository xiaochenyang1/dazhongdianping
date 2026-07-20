package com.tuowei.dazhongdianping.module.admin.rbac.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminPasswordResetRequest(
        @NotBlank(message = "新密码不能为空")
        @Size(min = 8, max = 72, message = "密码长度应为 8 到 72 个字符")
        String password
) {
}
