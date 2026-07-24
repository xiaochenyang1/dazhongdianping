package com.tuowei.dazhongdianping.module.auth.appeal.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserBanAppealSubmitRequest {

    @NotBlank(message = "type 不能为空")
    private String type;

    @NotBlank(message = "account 不能为空")
    private String account;

    @NotBlank(message = "code 不能为空")
    private String code;

    @NotBlank(message = "reason 不能为空")
    @Size(min = 10, max = 500, message = "申诉理由需要 10-500 字符")
    private String reason;
}
