package com.tuowei.dazhongdianping.module.admin.rbac.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;

public record AdminRoleSaveRequest(
        @NotBlank(message = "角色编码不能为空")
        @Pattern(regexp = "[a-z][a-z0-9_]{1,63}", message = "角色编码格式不合法")
        String code,
        @NotBlank(message = "角色名称不能为空")
        @Size(max = 64, message = "角色名称不能超过 64 个字符")
        String name,
        @Size(max = 255, message = "角色说明不能超过 255 个字符")
        String description,
        @NotEmpty(message = "至少选择一个权限")
        List<@NotNull(message = "权限不能为空") Long> permissionIds
) {
}
