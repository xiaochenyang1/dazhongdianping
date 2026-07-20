package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record MerchantStaffUpdateRequest(
        @NotBlank(message = "name 不能为空") String name,
        String phone,
        @Email(message = "email 格式不正确") String email,
        @NotEmpty(message = "roleIds 至少选择一个角色") List<Long> roleIds,
        Integer shopScopeType,
        List<Long> shopIds,
        Boolean resetPassword
) {
}
