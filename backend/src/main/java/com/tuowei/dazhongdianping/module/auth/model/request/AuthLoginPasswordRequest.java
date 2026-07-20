package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AuthLoginPasswordRequest {

    @NotBlank(message = "account 不能为空")
    private String account;

    @NotBlank(message = "password 不能为空")
    private String password;
}
