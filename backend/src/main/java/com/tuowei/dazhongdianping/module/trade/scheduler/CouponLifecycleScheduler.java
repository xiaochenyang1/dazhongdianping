package com.tuowei.dazhongdianping.module.trade.scheduler;

import com.tuowei.dazhongdianping.module.trade.service.CouponLifecycleService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class CouponLifecycleScheduler {

    private static final Logger log = LoggerFactory.getLogger(CouponLifecycleScheduler.class);

    private final CouponLifecycleService couponLifecycleService;

    public CouponLifecycleScheduler(CouponLifecycleService couponLifecycleService) {
        this.couponLifecycleService = couponLifecycleService;
    }

    @Scheduled(cron = "23 * * * * *")
    public void processDueCoupons() {
        try {
            couponLifecycleService.processDueCoupons();
        } catch (RuntimeException exception) {
            log.error("coupon lifecycle process failed", exception);
        }
    }
}
