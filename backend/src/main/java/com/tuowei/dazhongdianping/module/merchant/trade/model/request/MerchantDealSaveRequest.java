package com.tuowei.dazhongdianping.module.merchant.trade.model.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record MerchantDealSaveRequest(
        @NotNull Long shopId,
        @NotNull @Min(1) @Max(2) Integer type,
        @NotBlank @Size(max = 128) String title,
        @NotBlank @Size(max = 255) String coverImage,
        @NotNull @DecimalMin(value = "0.01") BigDecimal price,
        @NotNull @DecimalMin(value = "0.01") BigDecimal originalPrice,
        @NotBlank @Size(min = 3, max = 3) String currency,
        @NotNull @Min(-1) Integer stock,
        LocalDate validStart,
        LocalDate validEnd,
        @Size(max = 2000) String rules,
        @NotEmpty List<@Valid MerchantDealItemRequest> items
) {
}
