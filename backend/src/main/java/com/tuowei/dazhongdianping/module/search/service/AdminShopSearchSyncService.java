package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.search.mapper.SearchIndexSyncMapper;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncOverviewRow;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskQuery;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskRow;
import com.tuowei.dazhongdianping.module.search.model.response.AdminShopSearchSyncOverviewResponse;
import com.tuowei.dazhongdianping.module.search.model.response.AdminShopSearchSyncTaskResponse;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminShopSearchSyncService {

    private static final long MAX_LOCK_TIMEOUT_SECONDS = 24L * 60L * 60L;

    private final SearchProperties searchProperties;
    private final SearchIndexSyncMapper syncMapper;
    private final ShopSearchIndexService shopSearchIndexService;
    private final AdminAuditLogService auditLogService;

    public AdminShopSearchSyncService(SearchProperties searchProperties,
                                      SearchIndexSyncMapper syncMapper,
                                      ShopSearchIndexService shopSearchIndexService,
                                      AdminAuditLogService auditLogService) {
        this.searchProperties = searchProperties;
        this.syncMapper = syncMapper;
        this.shopSearchIndexService = shopSearchIndexService;
        this.auditLogService = auditLogService;
    }

    public AdminShopSearchSyncOverviewResponse overview() {
        String region = region();
        AuthorizedScope scope = currentScope(region);
        LocalDateTime now = LocalDateTime.now();
        ShopSearchSyncOverviewRow row = syncMapper.selectAdminSyncOverview(
                region,
                now,
                staleBefore(now),
                scope.allCities(),
                scope.cityIds(),
                scope.shopIds()
        );
        return new AdminShopSearchSyncOverviewResponse(
                region,
                searchProperties.getProvider().name().toLowerCase(Locale.ROOT),
                searchProperties.getIndexName(),
                searchProperties.getProvider() == SearchProperties.Provider.ELASTICSEARCH,
                value(row == null ? null : row.getTotalCount()),
                value(row == null ? null : row.getPendingCount()),
                value(row == null ? null : row.getProcessingCount()),
                value(row == null ? null : row.getRetryingCount()),
                value(row == null ? null : row.getStaleCount()),
                value(row == null ? null : row.getReadyCount())
        );
    }

    public PageResult<AdminShopSearchSyncTaskResponse> list(ShopSearchSyncTaskQuery query) {
        query.normalize();
        String region = region();
        AuthorizedScope scope = currentScope(region);
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime staleBefore = staleBefore(now);
        long total = syncMapper.countAdminShopSyncTasks(
                query, region, staleBefore, scope.allCities(), scope.cityIds(), scope.shopIds());
        List<AdminShopSearchSyncTaskResponse> tasks = syncMapper.selectAdminShopSyncTasks(
                        query, region, staleBefore, scope.allCities(), scope.cityIds(), scope.shopIds())
                .stream()
                .map(task -> toResponse(task, now, staleBefore))
                .toList();
        return new PageResult<>(
                tasks,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + tasks.size() < total
        );
    }

    @Transactional
    public int retry(Long shopId, String requestIp) {
        requireElasticsearchProvider();
        if (shopId == null || shopId <= 0) {
            throw new IllegalArgumentException("门店 ID 无效");
        }
        String region = region();
        AuthorizedScope scope = currentScope(region);
        int affected = syncMapper.retryAdminShopSyncTask(
                shopId, region, scope.allCities(), scope.cityIds(), scope.shopIds());
        if (affected != 1) {
            throw new NotFoundException("当前区域没有该搜索同步任务");
        }
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.search_sync_retry",
                "shop:" + shopId,
                "region=" + region,
                requestIp
        );
        return affected;
    }

    @Transactional
    public int retryFailed(String requestIp) {
        requireElasticsearchProvider();
        String region = region();
        AuthorizedScope scope = currentScope(region);
        int affected = syncMapper.retryAdminFailedShopSyncTasks(
                region,
                staleBefore(LocalDateTime.now()),
                scope.allCities(),
                scope.cityIds(),
                scope.shopIds()
        );
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.search_sync_retry_failed",
                "search_sync_tasks",
                "region=" + region + ", retried=" + affected,
                requestIp
        );
        return affected;
    }

    public int rebuildAll(String requestIp) {
        int indexed = shopSearchIndexService.rebuildAll();
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.search_reindex",
                "search_index:" + searchProperties.getIndexName(),
                "region=" + region() + ", indexed=" + indexed,
                requestIp
        );
        return indexed;
    }

    private AdminShopSearchSyncTaskResponse toResponse(ShopSearchSyncTaskRow task,
                                                       LocalDateTime now,
                                                       LocalDateTime staleBefore) {
        String state;
        String stateText;
        if (Integer.valueOf(1).equals(task.getStatus())) {
            if (task.getLockedAt() == null || !task.getLockedAt().isAfter(staleBefore)) {
                state = "stale";
                stateText = "处理超时";
            } else {
                state = "processing";
                stateText = "处理中";
            }
        } else if (value(task.getAttemptCount()) > 0) {
            state = "retrying";
            stateText = task.getNextRetryAt() != null && task.getNextRetryAt().isAfter(now)
                    ? "等待重试" : "重试待处理";
        } else {
            state = "pending";
            stateText = "待处理";
        }
        return new AdminShopSearchSyncTaskResponse(
                task.getShopId(),
                task.getShopName(),
                task.getRegion(),
                task.getCityName(),
                task.getVersion(),
                state,
                stateText,
                value(task.getAttemptCount()),
                task.getNextRetryAt(),
                task.getLockedAt(),
                task.getLastError(),
                task.getCreatedAt(),
                task.getUpdatedAt()
        );
    }

    private AuthorizedScope currentScope(String region) {
        AdminCityScope scope = currentAdmin().cityScopes().get(region);
        if (scope == null) {
            return new AuthorizedScope(false, Set.of(), Set.of());
        }
        return new AuthorizedScope(scope.allCities(), scope.cityIds(), scope.shopIds());
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员未登录");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private LocalDateTime staleBefore(LocalDateTime now) {
        long timeout = Math.max(
                30L,
                Math.min(searchProperties.getSyncLockTimeoutSeconds(), MAX_LOCK_TIMEOUT_SECONDS)
        );
        return now.minusSeconds(timeout);
    }

    private void requireElasticsearchProvider() {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            throw new IllegalArgumentException("APP_SEARCH_PROVIDER 必须为 elasticsearch 才能操作同步任务");
        }
    }

    private long value(Long value) {
        return value == null ? 0L : value;
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }

    private record AuthorizedScope(boolean allCities, Set<Long> cityIds, Set<Long> shopIds) {
        private AuthorizedScope {
            cityIds = cityIds == null ? Set.of() : Set.copyOf(cityIds);
            shopIds = shopIds == null ? Set.of() : Set.copyOf(shopIds);
        }
    }
}
