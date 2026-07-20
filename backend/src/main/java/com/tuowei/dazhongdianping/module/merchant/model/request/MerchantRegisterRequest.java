package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record MerchantRegisterRequest(
        @NotBlank(message = "account 不能为空")
        @Size(max = 128, message = "account 长度不能超过 128")
        String account,
        @NotBlank(message = "password 不能为空")
        @Size(min = 8, max = 64, message = "password 长度必须为 8-64")
        String password,
        @NotBlank(message = "companyName 不能为空")
        @Size(max = 128, message = "companyName 长度不能超过 128")
        String companyName,
        @NotBlank(message = "contactName 不能为空")
        @Size(max = 64, message = "contactName 长度不能超过 64")
        String contactName,
        @NotBlank(message = "contactPhone 不能为空")
        @Size(max = 32, message = "contactPhone 长度不能超过 32")
        String contactPhone,
        @Pattern(regexp = "CN|EU", message = "region 仅支持 CN 或 EU")
        String region
) {
}
