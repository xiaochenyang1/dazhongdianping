package com.tuowei.dazhongdianping.module.admin.user.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AdminAppUserStatusRequest {

    @NotBlank(message = "action 不能为空")
    private String action;

    @Size(max = 255, message = "reason 最长 255 字符")
    private String reason;
}
