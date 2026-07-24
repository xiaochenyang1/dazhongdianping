package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.NotNull;

public record MerchantSlotStatusRequest(
        @NotNull Boolean enabled
) {
}
