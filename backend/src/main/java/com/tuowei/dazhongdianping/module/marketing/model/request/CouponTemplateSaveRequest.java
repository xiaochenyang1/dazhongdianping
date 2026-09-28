package com.tuowei.dazhongdianping.module.marketing.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 运营创建/更新优惠券模板的请求。 */
public record CouponTemplateSaveRequest(
        @NotBlank @Size(max = 128) String name,
        @NotNull @Min(1) @Max(2) Integer type,
        @NotNull @DecimalMin("0") BigDecimal thresholdAmount,
        @NotNull @DecimalMin("0.01") BigDecimal discountAmount,
        @NotBlank @Size(min = 3, max = 3) String currency,
        @NotNull @Min(0) Long shopId,
        @NotNull @Min(0) Integer totalQuantity,
        @NotNull @Min(1) @Max(50) Integer perUserLimit,
        @NotNull @Min(1) @Max(365) Integer validDays,
        LocalDateTime claimStart,
        LocalDateTime claimEnd,
        @NotNull @Min(0) @Max(1) Integer status
) {
}
