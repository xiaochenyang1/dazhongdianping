package com.tuowei.dazhongdianping.module.invoice.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record InvoiceReceiptRequest(@NotBlank @Pattern(regexp = "[0-9a-f]{64}") String sha256) { }
