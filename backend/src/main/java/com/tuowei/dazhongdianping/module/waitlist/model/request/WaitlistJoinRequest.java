package com.tuowei.dazhongdianping.module.waitlist.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** 取号请求。tableType 1=小桌 2=中桌 3=大桌。 */
public record WaitlistJoinRequest(
        @NotNull @Min(1) @Max(3) Integer tableType,
        @NotNull @Min(1) @Max(50) Integer partySize
) {
}
