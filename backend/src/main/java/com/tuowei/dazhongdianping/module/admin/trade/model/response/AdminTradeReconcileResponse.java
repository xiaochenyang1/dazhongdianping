package com.tuowei.dazhongdianping.module.admin.trade.model.response;

public record AdminTradeReconcileResponse(
        int closedOrders,
        int restoredStockOrders,
        int failedPayments
) {
}
