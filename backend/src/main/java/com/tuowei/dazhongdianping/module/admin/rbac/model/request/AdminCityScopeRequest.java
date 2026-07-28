package com.tuowei.dazhongdianping.module.admin.rbac.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record AdminCityScopeRequest(
        @NotBlank(message = "城市范围区域不能为空")
        String region,
        @NotNull(message = "allCities 不能为空")
        Boolean allCities,
        @NotNull(message = "cityIds 不能为空")
        List<@NotNull(message = "城市 ID 不能为空") Long> cityIds,
        List<@NotNull(message = "门店 ID 不能为空") Long> shopIds
) {
}
