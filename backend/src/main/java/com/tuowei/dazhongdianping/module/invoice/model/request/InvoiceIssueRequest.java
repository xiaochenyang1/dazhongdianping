package com.tuowei.dazhongdianping.module.invoice.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record InvoiceIssueRequest(
        @NotBlank @Size(max = 64) String invoiceNo
) {
}
