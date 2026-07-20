package com.tuowei.dazhongdianping.module.merchant.shop.model.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ShopChangePhotosRequest(
        @NotNull(message = "相册不能为空")
        @Size(min = 1, max = 20, message = "相册必须包含 1 到 20 张图片")
        List<@Valid ShopChangePhotoRequest> photos
) {
}
