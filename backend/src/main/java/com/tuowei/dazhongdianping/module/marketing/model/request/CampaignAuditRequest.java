package com.tuowei.dazhongdianping.module.marketing.model.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 平台审核商家营销活动。approve=true 通过，false 驳回（需 reason）。 */
public record CampaignAuditRequest(
        @NotNull Boolean approve,
        @Size(max = 255) String reason
) {
}
