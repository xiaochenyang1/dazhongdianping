package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PolicyAcceptRequest {
    @NotNull
    @Min(1)
    @Max(3)
    private Integer policyType;

    @NotBlank
    @Size(max = 32)
    private String version;

    @NotBlank
    @Size(max = 16)
    @Pattern(regexp = "^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$")
    private String locale;

    @NotNull
    @Min(1)
    @Max(3)
    private Integer source;
}
