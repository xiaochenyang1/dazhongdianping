package com.tuowei.dazhongdianping.module.adpromo.model.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 平台审核广告投放的请求。approved=true 通过，false 驳回（需 rejectReason）。 */
public record AdAuditRequest(
        @NotNull Boolean approved,
        @Size(max = 255) String rejectReason
) {
}
