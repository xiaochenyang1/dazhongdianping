package com.tuowei.dazhongdianping.module.admin.merchant.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AdminMerchantStatusRequest {

    @NotBlank(message = "action 不能为空")
    private String action;

    @Size(max = 255, message = "reason 最长 255 字符")
    private String reason;
}
