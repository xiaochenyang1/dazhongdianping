package com.tuowei.dazhongdianping.module.invoice.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record TaxRateSaveRequest(
        @NotBlank @Size(max = 64) String name,
        @NotNull @Min(0) @Max(10000) Integer rateBp,
        @NotNull @Min(0) @Max(1) Integer status
) {
}
