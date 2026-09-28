package com.tuowei.dazhongdianping.module.consult.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** 发起（或复用）与某门店的咨询会话。 */
public record ConsultStartRequest(
        @NotNull @Min(1) Long shopId
) {
}
