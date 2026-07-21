package com.tuowei.dazhongdianping.module.admin.banner.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminBannerSaveRequest(
        @Min(value = 1, message = "cityId 最小为 1")
        Long cityId,
        @NotBlank(message = "title 不能为空")
        @Size(max = 128, message = "title 不能超过 128 字")
        String title,
        @Size(max = 255, message = "subtitle 不能超过 255 字")
        String subtitle,
        @NotBlank(message = "imageUrl 不能为空")
        @Size(max = 255, message = "imageUrl 不能超过 255 字")
        String imageUrl,
        @NotBlank(message = "linkUrl 不能为空")
        @Size(max = 255, message = "linkUrl 不能超过 255 字")
        String linkUrl,
        @NotNull(message = "sortNo 不能为空")
        @Min(value = 0, message = "sortNo 不能小于 0")
        Integer sortNo
) {
}
