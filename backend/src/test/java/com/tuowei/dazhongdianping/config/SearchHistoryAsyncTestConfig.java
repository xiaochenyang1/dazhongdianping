package com.tuowei.dazhongdianping.config;

import java.util.concurrent.Executor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.task.SyncTaskExecutor;

/**
 * Binds a synchronous {@code searchHistoryTaskExecutor} for the {@code test}
 * profile so {@code SearchHistoryRecorder.record} runs inline on the caller
 * thread. This keeps the write inside the test's {@code @Transactional} rollback
 * scope and preserves read-after-write assertions that immediately query search
 * history after a search request. Production uses the real pooled executor from
 * {@link SearchHistoryAsyncConfig}.
 */
@Configuration
@Profile("test")
public class SearchHistoryAsyncTestConfig {

    @Bean(name = "searchHistoryTaskExecutor")
    public Executor searchHistoryTaskExecutor() {
        return new SyncTaskExecutor();
    }
}
