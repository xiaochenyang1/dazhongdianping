package com.tuowei.dazhongdianping.config;

import java.util.concurrent.ThreadPoolExecutor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Executor for off-request-thread search-history writes (see
 * {@code SearchHistoryRecorder}). Excluded from the {@code test} profile, where a
 * synchronous executor is bound instead so history writes stay in the caller's
 * transaction. {@code CallerRunsPolicy} degrades to a synchronous write under
 * sustained load rather than dropping history silently.
 */
@Configuration
@Profile("!test")
public class SearchHistoryAsyncConfig {

    @Bean(name = "searchHistoryTaskExecutor")
    public ThreadPoolTaskExecutor searchHistoryTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(1);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(500);
        executor.setKeepAliveSeconds(30);
        executor.setThreadNamePrefix("search-history-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(10);
        executor.initialize();
        return executor;
    }
}
