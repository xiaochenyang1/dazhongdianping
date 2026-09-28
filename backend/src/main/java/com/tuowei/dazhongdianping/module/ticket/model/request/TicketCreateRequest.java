package com.tuowei.dazhongdianping.module.ticket.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** C 端发起客服工单。shopId 可省略，默认 0。 */
public record TicketCreateRequest(
        @NotBlank(message = "主题不能为空") @Size(max = 128, message = "主题过长") String subject,
        @NotBlank(message = "内容不能为空") @Size(max = 2000, message = "内容过长") String content,
        @Min(value = 0, message = "门店不存在") Long shopId
) {
}
