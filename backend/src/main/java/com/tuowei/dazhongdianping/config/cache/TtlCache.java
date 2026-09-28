package com.tuowei.dazhongdianping.config.cache;

import java.time.Duration;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.cache.support.AbstractValueAdaptingCache;
import org.springframework.cache.support.SimpleValueWrapper;

/**
 * Dependency-free {@link org.springframework.cache.Cache} with per-entry write
 * expiry, backed by a {@link ConcurrentHashMap}. Expired entries are evicted
 * lazily on access; a coarse size cap bounds memory if key cardinality ever
 * grows unexpectedly. Used for hot, non-personalized read paths where a short
 * bounded staleness is acceptable (see {@code CacheConfig}).
 */
public class TtlCache extends AbstractValueAdaptingCache {

    private final String name;
    private final long ttlNanos;
    private final int maxEntries;
    private final ConcurrentHashMap<Object, Entry> store = new ConcurrentHashMap<>();

    public TtlCache(String name, Duration ttl, int maxEntries) {
        super(true);
        this.name = name;
        this.ttlNanos = ttl.toNanos();
        this.maxEntries = maxEntries;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public Object getNativeCache() {
        return store;
    }

    @Override
    protected Object lookup(Object key) {
        Entry entry = store.get(key);
        if (entry == null) {
            return null;
        }
        if (entry.isExpired()) {
            store.remove(key, entry);
            return null;
        }
        return entry.value;
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T get(Object key, Callable<T> valueLoader) {
        ValueWrapper existing = get(key);
        if (existing != null) {
            return (T) existing.get();
        }
        synchronized (this) {
            existing = get(key);
            if (existing != null) {
                return (T) existing.get();
            }
            T value;
            try {
                value = valueLoader.call();
            } catch (Exception ex) {
                throw new ValueRetrievalException(key, valueLoader, ex);
            }
            put(key, value);
            return value;
        }
    }

    @Override
    public void put(Object key, Object value) {
        purgeIfNeeded();
        store.put(key, new Entry(toStoreValue(value), System.nanoTime() + ttlNanos));
    }

    @Override
    public ValueWrapper putIfAbsent(Object key, Object value) {
        Entry existing = store.get(key);
        if (existing != null && !existing.isExpired()) {
            return new SimpleValueWrapper(fromStoreValue(existing.value));
        }
        put(key, value);
        return null;
    }

    @Override
    public void evict(Object key) {
        store.remove(key);
    }

    @Override
    public void clear() {
        store.clear();
    }

    private void purgeIfNeeded() {
        if (store.size() < maxEntries) {
            return;
        }
        store.values().removeIf(Entry::isExpired);
        if (store.size() >= maxEntries) {
            store.clear();
        }
    }

    private static final class Entry {
        private final Object value;
        private final long expiresAtNanos;

        private Entry(Object value, long expiresAtNanos) {
            this.value = value;
            this.expiresAtNanos = expiresAtNanos;
        }

        private boolean isExpired() {
            return System.nanoTime() - expiresAtNanos >= 0;
        }
    }
}
