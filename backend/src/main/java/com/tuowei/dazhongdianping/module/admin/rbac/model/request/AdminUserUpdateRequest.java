package com.tuowei.dazhongdianping.module.admin.rbac.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record AdminUserUpdateRequest(
        @NotBlank(message = "管理员名称不能为空")
        @Size(max = 64, message = "管理员名称不能超过 64 个字符")
        String name,
        @NotEmpty(message = "至少选择一个角色")
        List<@NotNull(message = "角色不能为空") Long> roleIds,
        @NotEmpty(message = "至少选择一个区域")
        List<@NotBlank(message = "区域不能为空") String> regions
) {
}
