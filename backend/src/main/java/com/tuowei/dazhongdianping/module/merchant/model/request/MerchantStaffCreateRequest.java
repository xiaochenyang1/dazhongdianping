package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record MerchantStaffCreateRequest(
        @NotBlank(message = "account 不能为空") String account,
        @NotBlank(message = "password 不能为空")
        @Size(min = 8, max = 64, message = "password 长度必须为 8-64") String password,
        @NotBlank(message = "name 不能为空") String name,
        String phone,
        @Email(message = "email 格式不正确") String email,
        @NotEmpty(message = "roleIds 至少选择一个角色") List<Long> roleIds,
        Integer shopScopeType,
        List<Long> shopIds
) {
}
