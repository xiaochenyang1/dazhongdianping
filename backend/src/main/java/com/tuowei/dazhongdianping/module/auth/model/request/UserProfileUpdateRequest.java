package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserProfileUpdateRequest {

    @Size(max = 64, message = "nickname 不能超过 64 字")
    private String nickname = "";

    @Size(max = 255, message = "avatar 不能超过 255 字")
    private String avatar = "";

    private Integer gender = 0;

    @Size(max = 255, message = "signature 不能超过 255 字")
    private String signature = "";
}
