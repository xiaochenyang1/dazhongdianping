package com.tuowei.dazhongdianping.module.merchant.shop.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record ShopChangeDishRequest(
        @NotBlank(message = "菜品名称不能为空")
        @Size(max = 64, message = "菜品名称不能超过 64 个字符") String name,
        @NotNull(message = "菜品价格不能为空")
        @DecimalMin(value = "0.00", message = "菜品价格不能为负数") BigDecimal price,
        @Size(max = 255, message = "推荐理由不能超过 255 个字符") String recommendReason,
        @NotNull(message = "菜品排序不能为空")
        @Min(value = 0, message = "菜品排序不能小于 0") Integer sort
) {
}
