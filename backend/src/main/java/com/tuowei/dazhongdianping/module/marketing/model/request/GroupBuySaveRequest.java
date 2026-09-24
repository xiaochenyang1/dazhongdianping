package com.tuowei.dazhongdianping.module.marketing.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 商家创建拼团活动。成团人数 2-10。 */
public record GroupBuySaveRequest(
        @NotNull Long shopId,
        @NotNull Long dealId,
        @NotBlank @Size(max = 128) String title,
        @NotNull @DecimalMin("0.01") BigDecimal groupPrice,
        @NotNull @Min(2) @Max(10) Integer groupSize,
        @NotNull LocalDateTime startAt,
        @NotNull LocalDateTime endAt
) {
}
