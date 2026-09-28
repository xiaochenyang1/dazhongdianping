package com.tuowei.dazhongdianping.module.complaint.model.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 平台仲裁处置的请求。resolved=true 解决（status→3），false 驳回（status→4）。 */
public record ComplaintDisposeRequest(
        @NotNull Boolean resolved,
        @NotNull @Size(min = 1, max = 2000) String resolution
) {
}
