package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AuthRefreshRequest {

    @NotBlank(message = "refreshToken 不能为空")
    private String refreshToken;
}
