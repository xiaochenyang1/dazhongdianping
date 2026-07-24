package com.tuowei.dazhongdianping.module.auth.appeal.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserBanAppealQueryRequest {

    @NotBlank(message = "type 不能为空")
    private String type;

    @NotBlank(message = "account 不能为空")
    private String account;

    @NotBlank(message = "code 不能为空")
    private String code;
}
