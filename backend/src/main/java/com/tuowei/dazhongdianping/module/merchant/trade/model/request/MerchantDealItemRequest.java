package com.tuowei.dazhongdianping.module.merchant.trade.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record MerchantDealItemRequest(
        @NotBlank @Size(max = 128) String name,
        @NotNull @Min(1) Integer quantity,
        @NotNull @DecimalMin("0.00") BigDecimal price,
        @NotNull @Min(0) Integer sort
) {
}
