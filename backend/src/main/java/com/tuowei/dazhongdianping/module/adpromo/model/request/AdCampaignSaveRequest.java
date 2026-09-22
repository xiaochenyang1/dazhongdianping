package com.tuowei.dazhongdianping.module.adpromo.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/** 商家创建/更新广告投放的请求。 */
public record AdCampaignSaveRequest(
        @NotNull @Min(1) Long shopId,
        @NotBlank @Size(max = 128) String name,
        @NotNull @Min(1) @Max(2) Integer slotType,
        @Size(max = 64) String keyword,
        @NotNull @DecimalMin("0.01") BigDecimal bidCpc,
        @NotNull @DecimalMin("0") BigDecimal dailyBudget
) {
}
