package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.NotBlank;

public record MerchantRejectReservationRequest(
        @NotBlank(message = "reason 不能为空") String reason
) {
}
