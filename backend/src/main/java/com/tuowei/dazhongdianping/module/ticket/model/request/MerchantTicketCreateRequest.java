package com.tuowei.dazhongdianping.module.ticket.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 商家向平台发起客服工单。 */
public record MerchantTicketCreateRequest(
        @NotBlank(message = "主题不能为空") @Size(max = 128, message = "主题过长") String subject,
        @NotBlank(message = "内容不能为空") @Size(max = 2000, message = "内容过长") String content,
        @NotNull(message = "请选择门店") @Min(value = 1, message = "门店不存在") Long shopId
) {
}
