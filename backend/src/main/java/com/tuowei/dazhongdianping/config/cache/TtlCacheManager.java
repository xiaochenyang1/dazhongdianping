package com.tuowei.dazhongdianping.config.cache;

import java.time.Duration;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;

/**
 * {@link CacheManager} backing every named cache with a {@link TtlCache}. Only
 * the caches named at construction are served; unknown names return {@code null}
 * so a mis-typed cache name fails fast rather than silently caching forever.
 */
public class TtlCacheManager implements CacheManager {

    private final ConcurrentHashMap<String, Cache> caches = new ConcurrentHashMap<>();

    public TtlCacheManager(Duration ttl, int maxEntriesPerCache, String... cacheNames) {
        for (String cacheName : cacheNames) {
            caches.put(cacheName, new TtlCache(cacheName, ttl, maxEntriesPerCache));
        }
    }

    @Override
    public Cache getCache(String name) {
        return caches.get(name);
    }

    @Override
    public Collection<String> getCacheNames() {
        return List.copyOf(caches.keySet());
    }
}
