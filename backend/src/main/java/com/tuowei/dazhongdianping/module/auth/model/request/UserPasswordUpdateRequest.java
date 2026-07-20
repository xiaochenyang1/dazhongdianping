package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserPasswordUpdateRequest {

    private String oldPassword = "";

    @NotBlank(message = "newPassword 不能为空")
    private String newPassword;
}
