package com.tuowei.dazhongdianping.module.marketing.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/** 商家自助建券。创建后待平台审核，通过前不进入领券中心。 */
public record MerchantCouponCreateRequest(
        @NotBlank @Size(max = 128) String name,
        @NotNull @Min(1) @Max(2) Integer type,
        @NotNull @DecimalMin("0") BigDecimal thresholdAmount,
        @NotNull @DecimalMin("0.01") BigDecimal discountAmount,
        @NotNull Long shopId,
        @NotNull @Min(0) Integer totalQuantity,
        @NotNull @Min(1) @Max(50) Integer perUserLimit,
        @NotNull @Min(1) @Max(365) Integer validDays
) {
}
