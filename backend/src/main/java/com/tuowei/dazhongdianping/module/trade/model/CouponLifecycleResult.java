package com.tuowei.dazhongdianping.module.trade.model;

public record CouponLifecycleResult(
        int expiredMarked,
        int threeDayReminders,
        int oneDayReminders,
        int skipped
) {
}
