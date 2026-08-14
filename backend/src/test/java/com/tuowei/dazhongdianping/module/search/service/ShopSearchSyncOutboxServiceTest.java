package com.tuowei.dazhongdianping.module.search.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.search.mapper.SearchIndexSyncMapper;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskRow;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ShopSearchSyncOutboxServiceTest {

    @Mock
    private SearchIndexSyncMapper syncMapper;

    @Mock
    private ShopSearchIndexService shopSearchIndexService;

    private SearchProperties searchProperties;
    private ShopSearchSyncOutboxService service;

    @BeforeEach
    void setUp() {
        searchProperties = new SearchProperties();
        service = new ShopSearchSyncOutboxService(
                searchProperties,
                syncMapper,
                shopSearchIndexService
        );
    }

    @Test
    void shouldSkipEnqueueAndDispatchWhenElasticsearchIsDisabled() {
        service.enqueue(1001L);

        assertThat(service.dispatchDueTasks()).isZero();
        verifyNoInteractions(syncMapper, shopSearchIndexService);
    }

    @Test
    void shouldValidateAndEnqueueShopWhenElasticsearchIsEnabled() {
        searchProperties.setProvider(SearchProperties.Provider.ELASTICSEARCH);

        assertThatThrownBy(() -> service.enqueue(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("搜索索引同步任务缺少有效门店 ID");
        assertThatThrownBy(() -> service.enqueue(0L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("搜索索引同步任务缺少有效门店 ID");

        service.enqueue(1001L);

        verify(syncMapper).enqueueShopSync(1001L);
    }

    @Test
    void shouldClaimOnlyAvailableTasksAndCountSuccessfulCompletions() {
        searchProperties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        searchProperties.setSyncBatchSize(2);
        searchProperties.setSyncLockTimeoutSeconds(1);
        ShopSearchSyncTaskRow lostClaim = task(1001L, 11L, 0);
        ShopSearchSyncTaskRow completed = task(1002L, 12L, 0);
        ShopSearchSyncTaskRow completionLost = task(1003L, 13L, 0);
        when(syncMapper.selectDueShopSyncTasks(any(), any(), eq(4)))
                .thenReturn(List.of(lostClaim, completed, completionLost));
        when(syncMapper.claimShopSyncTask(eq(1001L), eq(11L), any(), any())).thenReturn(0);
        when(syncMapper.claimShopSyncTask(eq(1002L), eq(12L), any(), any())).thenReturn(1);
        when(syncMapper.claimShopSyncTask(eq(1003L), eq(13L), any(), any())).thenReturn(1);
        when(syncMapper.completeShopSyncTask(1002L, 12L)).thenReturn(1);
        when(syncMapper.completeShopSyncTask(1003L, 13L)).thenReturn(0);

        int count = service.dispatchDueTasks();

        assertThat(count).isEqualTo(1);
        verify(shopSearchIndexService, never()).syncShop(1001L);
        verify(shopSearchIndexService).syncShop(1002L);
        verify(shopSearchIndexService).syncShop(1003L);
        verify(syncMapper).completeShopSyncTask(1002L, 12L);
        verify(syncMapper).completeShopSyncTask(1003L, 13L);

        ArgumentCaptor<LocalDateTime> nowCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        ArgumentCaptor<LocalDateTime> staleCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(syncMapper).selectDueShopSyncTasks(nowCaptor.capture(), staleCaptor.capture(), eq(4));
        assertThat(staleCaptor.getValue()).isEqualTo(nowCaptor.getValue().minusSeconds(30));
    }

    @Test
    void shouldRescheduleFailureWithCappedBackoffAndTruncatedDeepestError() {
        searchProperties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        searchProperties.setSyncBatchSize(1);
        searchProperties.setSyncRetryBaseSeconds(10);
        searchProperties.setSyncRetryMaxSeconds(35);
        ShopSearchSyncTaskRow failed = task(2001L, 21L, 3);
        when(syncMapper.selectDueShopSyncTasks(any(), any(), eq(2))).thenReturn(List.of(failed));
        when(syncMapper.claimShopSyncTask(eq(2001L), eq(21L), any(), any())).thenReturn(1);
        String deepestError = "x".repeat(1_050);
        org.mockito.Mockito.doThrow(new IllegalStateException(
                        "outer detail",
                        new IllegalArgumentException("  " + deepestError + "  ")))
                .when(shopSearchIndexService).syncShop(2001L);
        when(syncMapper.rescheduleShopSyncTask(eq(2001L), eq(21L), any(), any()))
                .thenReturn(1);
        LocalDateTime earliestRetry = LocalDateTime.now().plusSeconds(34);

        int count = service.dispatchDueTasks();

        LocalDateTime latestRetry = LocalDateTime.now().plusSeconds(36);
        assertThat(count).isZero();
        verify(syncMapper, never()).completeShopSyncTask(any(), any());
        ArgumentCaptor<LocalDateTime> retryAtCaptor = ArgumentCaptor.forClass(LocalDateTime.class);
        ArgumentCaptor<String> errorCaptor = ArgumentCaptor.forClass(String.class);
        verify(syncMapper).rescheduleShopSyncTask(
                eq(2001L), eq(21L), retryAtCaptor.capture(), errorCaptor.capture());
        assertThat(retryAtCaptor.getValue()).isBetween(earliestRetry, latestRetry);
        assertThat(errorCaptor.getValue())
                .hasSize(1_000)
                .isEqualTo(deepestError.substring(0, 1_000));
    }

    private ShopSearchSyncTaskRow task(Long shopId, Long version, Integer attemptCount) {
        ShopSearchSyncTaskRow task = new ShopSearchSyncTaskRow();
        task.setShopId(shopId);
        task.setVersion(version);
        task.setAttemptCount(attemptCount);
        return task;
    }
}
