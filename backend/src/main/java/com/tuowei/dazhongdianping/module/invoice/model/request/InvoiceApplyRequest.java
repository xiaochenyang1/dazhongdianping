package com.tuowei.dazhongdianping.module.invoice.model.request;

import jakarta.validation.constraints.NotNull;

public record InvoiceApplyRequest(
        @NotNull Long orderId,
        @NotNull Long titleId
) {
}
