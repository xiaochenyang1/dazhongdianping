package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PrivacyDeleteTaskCreateRequest {

    @NotBlank(message = "verifyType 不能为空")
    private String verifyType;

    @NotBlank(message = "account 不能为空")
    private String account;

    @Size(max = 32, message = "verifyCode 不能超过 32 字")
    private String verifyCode;

    @Size(max = 64, message = "password 不能超过 64 字")
    private String password;

    @NotBlank(message = "reason 不能为空")
    @Size(max = 255, message = "reason 不能超过 255 字")
    private String reason;
}
