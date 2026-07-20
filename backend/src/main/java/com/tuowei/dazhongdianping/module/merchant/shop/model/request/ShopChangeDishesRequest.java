package com.tuowei.dazhongdianping.module.merchant.shop.model.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ShopChangeDishesRequest(
        @NotNull(message = "菜单不能为空")
        @Size(max = 100, message = "菜单不能超过 100 个菜品")
        List<@Valid ShopChangeDishRequest> dishes
) {
}
