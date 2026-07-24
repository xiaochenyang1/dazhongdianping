package com.tuowei.dazhongdianping.module.trade.model;

public record TradeReconcileResult(
        int closedOrders,
        int restoredStockOrders,
        int failedPayments
) {
}
