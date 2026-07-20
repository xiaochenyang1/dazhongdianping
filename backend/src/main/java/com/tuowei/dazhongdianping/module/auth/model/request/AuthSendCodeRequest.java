package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AuthSendCodeRequest {

    @NotBlank(message = "scene 不能为空")
    private String scene;

    @NotBlank(message = "type 不能为空")
    private String type;

    @NotBlank(message = "account 不能为空")
    private String account;

    private String deviceId = "";
}
