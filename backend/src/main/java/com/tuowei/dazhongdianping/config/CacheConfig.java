package com.tuowei.dazhongdianping.config;

import com.tuowei.dazhongdianping.config.cache.TtlCacheManager;
import java.time.Duration;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * In-process caching for hot, non-personalized read paths (home banners and
 * rank leaderboards). A short write-expiry TTL keeps the cache correct by
 * construction — data is at most {@link #TTL_SECONDS}s stale and self-heals, so
 * no explicit eviction is wired on admin writes. Personalized recommendation
 * feeds are intentionally not cached (per-user, per-location, low hit rate).
 *
 * <p>Excluded from the {@code test} profile: without {@code @EnableCaching}
 * active there, the {@code @Cacheable} annotations are inert, so existing
 * read-after-write and admin-mutation tests observe fresh data every call.
 */
@Configuration
@Profile("!test")
@EnableCaching
public class CacheConfig {

    public static final String HOME_BANNERS = "homeBanners";
    public static final String RANK_LIST = "rankList";
    public static final String RANK_DETAIL = "rankDetail";

    private static final long TTL_SECONDS = 60;
    private static final int MAX_ENTRIES_PER_CACHE = 2_000;

    @Bean
    public CacheManager cacheManager() {
        return new TtlCacheManager(
                Duration.ofSeconds(TTL_SECONDS),
                MAX_ENTRIES_PER_CACHE,
                HOME_BANNERS, RANK_LIST, RANK_DETAIL);
    }
}
