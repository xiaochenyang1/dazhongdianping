package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AuthLoginCodeRequest {

    @NotBlank(message = "type 不能为空")
    private String type;

    @NotBlank(message = "account 不能为空")
    private String account;

    @NotBlank(message = "code 不能为空")
    private String code;

    private String preferredRegion = "";
}
