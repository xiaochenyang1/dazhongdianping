package com.tuowei.dazhongdianping.module.merchant.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record MerchantSettlementApplyRequest(
        @NotBlank(message = "licenseUrl 不能为空")
        @Size(max = 255, message = "licenseUrl 长度不能超过 255")
        String licenseUrl,
        @NotBlank(message = "legalPerson 不能为空")
        @Size(max = 64, message = "legalPerson 长度不能超过 64")
        String legalPerson,
        @NotEmpty(message = "shopPhotoUrls 至少上传一张门店照片")
        @Size(max = 12, message = "shopPhotoUrls 最多 12 张")
        List<@NotBlank(message = "门店照片地址不能为空") String> shopPhotoUrls
) {
}
