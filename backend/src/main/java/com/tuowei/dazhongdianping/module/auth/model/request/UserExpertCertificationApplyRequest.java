package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserExpertCertificationApplyRequest {

    @NotBlank(message = "reason 不能为空")
    @Size(max = 500, message = "reason 不能超过 500 字")
    private String reason = "";
}
