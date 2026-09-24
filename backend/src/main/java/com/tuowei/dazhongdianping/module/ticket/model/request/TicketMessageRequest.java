package com.tuowei.dazhongdianping.module.ticket.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 工单回复。 */
public record TicketMessageRequest(
        @NotBlank(message = "内容不能为空") @Size(max = 2000, message = "内容过长") String content
) {
}
