package com.tuowei.dazhongdianping.module.ticket.model.request;

import jakarta.validation.constraints.NotNull;

/** 平台更新工单状态。仅允许 2 处理中、3 已解决、4 已关闭。 */
public record TicketStatusRequest(
        @NotNull(message = "请选择状态") Integer status
) {
}
