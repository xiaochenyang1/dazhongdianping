package com.tuowei.dazhongdianping.module.merchant.shop.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ShopChangePhotoRequest(
        @NotBlank(message = "图片地址不能为空")
        @Size(max = 255, message = "图片地址不能超过 255 个字符") String imageUrl,
        @NotNull(message = "图片类型不能为空")
        @Min(value = 1, message = "图片类型非法")
        @Max(value = 3, message = "图片类型非法") Integer photoType,
        @NotNull(message = "图片排序不能为空")
        @Min(value = 0, message = "图片排序不能小于 0") Integer sort
) {
}
