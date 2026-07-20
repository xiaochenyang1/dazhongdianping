package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public record MerchantStaffStatusRequest(
        @Min(value = 1, message = "status 仅支持 1 或 2")
        @Max(value = 2, message = "status 仅支持 1 或 2")
        Integer status
) {
}
