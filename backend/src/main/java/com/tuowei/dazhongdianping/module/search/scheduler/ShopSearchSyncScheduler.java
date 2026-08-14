package com.tuowei.dazhongdianping.module.search.scheduler;

import com.tuowei.dazhongdianping.module.search.service.ShopSearchSyncOutboxService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class ShopSearchSyncScheduler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShopSearchSyncScheduler.class);

    private final ShopSearchSyncOutboxService syncOutboxService;

    public ShopSearchSyncScheduler(ShopSearchSyncOutboxService syncOutboxService) {
        this.syncOutboxService = syncOutboxService;
    }

    @Scheduled(
            fixedDelayString = "${app.search.sync-fixed-delay-ms:5000}",
            initialDelayString = "${app.search.sync-initial-delay-ms:10000}")
    public void dispatchShopSearchSyncTasks() {
        try {
            int completed = syncOutboxService.dispatchDueTasks();
            if (completed > 0) {
                LOGGER.info("Shop search sync completed: count={}", completed);
            }
        } catch (RuntimeException exception) {
            LOGGER.error("Shop search sync dispatch failed", exception);
        }
    }
}
