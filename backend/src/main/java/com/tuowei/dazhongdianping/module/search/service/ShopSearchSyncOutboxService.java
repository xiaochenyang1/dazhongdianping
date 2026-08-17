package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.search.mapper.SearchIndexSyncMapper;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskRow;
import java.time.LocalDateTime;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ShopSearchSyncOutboxService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShopSearchSyncOutboxService.class);
    private static final int MAX_ERROR_LENGTH = 1000;
    private static final long MAX_LOCK_TIMEOUT_SECONDS = 24L * 60L * 60L;
    private static final long MAX_RETRY_DELAY_SECONDS = 7L * 24L * 60L * 60L;

    private final SearchProperties searchProperties;
    private final SearchIndexSyncMapper syncMapper;
    private final ShopSearchIndexService shopSearchIndexService;

    public ShopSearchSyncOutboxService(SearchProperties searchProperties,
                                       SearchIndexSyncMapper syncMapper,
                                       ShopSearchIndexService shopSearchIndexService) {
        this.searchProperties = searchProperties;
        this.syncMapper = syncMapper;
        this.shopSearchIndexService = shopSearchIndexService;
    }

    @Transactional
    public void enqueue(Long shopId) {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            return;
        }
        if (shopId == null || shopId <= 0) {
            throw new IllegalArgumentException("搜索索引同步任务缺少有效门店 ID");
        }
        syncMapper.enqueueShopSync(shopId);
    }

    public int dispatchDueTasks() {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            return 0;
        }

        int batchSize = Math.max(1, Math.min(searchProperties.getSyncBatchSize(), 200));
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime staleBefore = now.minusSeconds(normalizedLockTimeoutSeconds());
        List<ShopSearchSyncTaskRow> candidates = syncMapper.selectDueShopSyncTasks(
                now, staleBefore, batchSize * 2);

        int completed = 0;
        int claimed = 0;
        for (ShopSearchSyncTaskRow task : candidates) {
            if (claimed >= batchSize) {
                break;
            }
            LocalDateTime claimedAt = LocalDateTime.now();
            LocalDateTime claimStaleBefore = claimedAt.minusSeconds(normalizedLockTimeoutSeconds());
            if (syncMapper.claimShopSyncTask(
                    task.getShopId(), task.getVersion(), claimedAt, claimStaleBefore) != 1) {
                continue;
            }
            claimed++;
            try {
                shopSearchIndexService.syncShop(task.getShopId());
                if (syncMapper.completeShopSyncTask(task.getShopId(), task.getVersion()) == 1) {
                    completed++;
                }
            } catch (RuntimeException exception) {
                reschedule(task, exception);
            }
        }
        return completed;
    }

    private void reschedule(ShopSearchSyncTaskRow task, RuntimeException exception) {
        int nextAttempt = Math.max(0, task.getAttemptCount() == null ? 0 : task.getAttemptCount()) + 1;
        long retryDelaySeconds = retryDelaySeconds(nextAttempt);
        String error = normalizeError(exception);
        int affected = syncMapper.rescheduleShopSyncTask(
                task.getShopId(),
                task.getVersion(),
                LocalDateTime.now().plusSeconds(retryDelaySeconds),
                error
        );
        if (affected == 1) {
            LOGGER.warn(
                    "Shop search sync failed; retry scheduled: shopId={}, version={}, attempt={}, delaySeconds={}, error={}",
                    task.getShopId(), task.getVersion(), nextAttempt, retryDelaySeconds, error
            );
        }
    }

    private long retryDelaySeconds(int attempt) {
        long maximum = Math.max(
                1L,
                Math.min(searchProperties.getSyncRetryMaxSeconds(), MAX_RETRY_DELAY_SECONDS)
        );
        long delay = Math.min(maximum, Math.max(1L, searchProperties.getSyncRetryBaseSeconds()));
        int doublings = Math.min(30, Math.max(0, attempt - 1));
        for (int index = 0; index < doublings && delay < maximum; index++) {
            delay = Math.min(maximum, delay * 2L);
        }
        return delay;
    }

    private long normalizedLockTimeoutSeconds() {
        return Math.max(
                30L,
                Math.min(searchProperties.getSyncLockTimeoutSeconds(), MAX_LOCK_TIMEOUT_SECONDS)
        );
    }

    private String normalizeError(RuntimeException exception) {
        Throwable cursor = exception;
        String message = null;
        while (cursor != null) {
            if (cursor.getMessage() != null && !cursor.getMessage().isBlank()) {
                message = cursor.getMessage().trim();
            }
            cursor = cursor.getCause();
        }
        if (message == null) {
            message = exception.getClass().getSimpleName();
        }
        return message.length() <= MAX_ERROR_LENGTH ? message : message.substring(0, MAX_ERROR_LENGTH);
    }
}
