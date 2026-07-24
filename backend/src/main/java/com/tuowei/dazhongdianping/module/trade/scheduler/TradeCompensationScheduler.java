package com.tuowei.dazhongdianping.module.trade.scheduler;

import com.tuowei.dazhongdianping.module.trade.service.TradeCompensationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class TradeCompensationScheduler {

    private static final Logger log = LoggerFactory.getLogger(TradeCompensationScheduler.class);

    private final TradeCompensationService compensationService;

    public TradeCompensationScheduler(TradeCompensationService compensationService) {
        this.compensationService = compensationService;
    }

    @Scheduled(cron = "17 * * * * *")
    public void reconcileExpiredTrades() {
        try {
            compensationService.reconcile();
        } catch (RuntimeException exception) {
            log.error("trade compensation reconcile failed", exception);
        }
    }
}
