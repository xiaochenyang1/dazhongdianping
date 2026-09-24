package com.tuowei.dazhongdianping.module.invoice.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record InvoiceTitleSaveRequest(
        @NotNull @Min(1) @Max(2) Integer titleType,
        @NotBlank @Size(max = 128) String name,
        @Size(max = 64) String taxNo,
        @Size(max = 128) String email,
        Boolean isDefault
) {
}
