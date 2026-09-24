package com.tuowei.dazhongdianping.module.openapi.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 创建开放平台应用。 */
public record OpenAppCreateRequest(
        @NotBlank(message = "应用名称不能为空") @Size(max = 128, message = "应用名称过长") String name,
        @NotNull(message = "请填写所属商户") @Min(value = 0, message = "所属商户无效") Long ownerMerchantId
) {
}
