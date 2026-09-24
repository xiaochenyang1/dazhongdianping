package com.tuowei.dazhongdianping.module.marketing.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** 商家创建秒杀场次。时间使用 ISO-8601。 */
public record SeckillSaveRequest(
        @NotNull Long shopId,
        @NotNull Long dealId,
        @NotBlank @Size(max = 128) String title,
        @NotNull @DecimalMin("0.01") BigDecimal seckillPrice,
        @NotNull @Min(1) Integer stock,
        @NotNull LocalDateTime startAt,
        @NotNull LocalDateTime endAt
) {
}
