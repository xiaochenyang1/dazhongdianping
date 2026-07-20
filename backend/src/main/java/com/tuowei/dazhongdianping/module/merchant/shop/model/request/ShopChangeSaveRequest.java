package com.tuowei.dazhongdianping.module.merchant.shop.model.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public record ShopChangeSaveRequest(
        @NotNull(message = "分类不能为空") Long categoryId,
        @NotNull(message = "城市不能为空") Long cityId,
        @NotNull(message = "商圈不能为空") Long areaId,
        @NotBlank(message = "门店名称不能为空")
        @Size(max = 128, message = "门店名称不能超过 128 个字符") String name,
        @NotBlank(message = "封面不能为空")
        @Size(max = 255, message = "封面地址不能超过 255 个字符") String coverUrl,
        @Size(max = 64, message = "电话不能超过 64 个字符") String phone,
        @NotNull(message = "人均价格不能为空")
        @DecimalMin(value = "0.00", message = "人均价格不能为负数") BigDecimal pricePerCapita,
        @NotBlank(message = "币种不能为空")
        @Pattern(regexp = "[A-Za-z]{3}", message = "币种必须是三位字母") String currency,
        @NotBlank(message = "地址不能为空")
        @Size(max = 255, message = "地址不能超过 255 个字符") String address,
        @DecimalMin(value = "-90", message = "纬度不能小于 -90")
        @DecimalMax(value = "90", message = "纬度不能大于 90") BigDecimal latitude,
        @DecimalMin(value = "-180", message = "经度不能小于 -180")
        @DecimalMax(value = "180", message = "经度不能大于 180") BigDecimal longitude,
        @NotBlank(message = "营业时间不能为空")
        @Size(max = 128, message = "营业时间不能超过 128 个字符") String businessHours,
        @NotBlank(message = "门店简介不能为空")
        @Size(max = 255, message = "门店简介不能超过 255 个字符") String summary,
        @NotNull(message = "营业状态不能为空") Boolean openNow,
        @Size(max = 20, message = "门店标签不能超过 20 个") List<@Size(max = 32) String> tags
) {
}
