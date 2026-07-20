package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserDevicePushTokenUpdateRequest {
    @NotNull
    @Min(0)
    @Max(3)
    private Integer pushChannel;

    @Size(max = 255)
    private String pushToken;

    @NotBlank
    @Size(max = 32)
    private String appVersion;
}
