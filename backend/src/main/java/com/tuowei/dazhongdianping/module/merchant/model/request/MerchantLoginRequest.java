package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.NotBlank;

public record MerchantLoginRequest(
        @NotBlank(message = "account 不能为空") String account,
        @NotBlank(message = "password 不能为空") String password
) {
}
