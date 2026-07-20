package com.tuowei.dazhongdianping.module.merchant.trade.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record MerchantDealStatusRequest(@NotNull @Min(0) @Max(1) Integer status) {
}
