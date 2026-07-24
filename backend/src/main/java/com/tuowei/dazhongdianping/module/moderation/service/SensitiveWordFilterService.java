package com.tuowei.dazhongdianping.module.moderation.service;

import com.tuowei.dazhongdianping.module.moderation.mapper.SensitiveWordMapper;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class SensitiveWordFilterService {

    private final SensitiveWordMapper mapper;
    private final ConcurrentMap<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public SensitiveWordFilterService(SensitiveWordMapper mapper) {
        this.mapper = mapper;
    }

    public void assertClean(String region, String... texts) {
        List<String> hits = findHits(region, texts);
        if (!hits.isEmpty()) {
            throw new IllegalArgumentException("内容包含敏感词：" + String.join("、", hits));
        }
    }

    public List<String> findHits(String region, String... texts) {
        if (!StringUtils.hasText(region)) {
            return List.of();
        }
        List<String> words = enabledWords(region);
        if (words.isEmpty()) {
            return List.of();
        }
        StringBuilder joined = new StringBuilder();
        for (String text : texts) {
            if (StringUtils.hasText(text)) {
                joined.append(text).append('\n');
            }
        }
        if (joined.isEmpty()) {
            return List.of();
        }
        String haystack = joined.toString().toLowerCase(Locale.ROOT);
        List<String> hits = new ArrayList<>();
        for (String word : words) {
            if (!StringUtils.hasText(word)) {
                continue;
            }
            if (haystack.contains(word.toLowerCase(Locale.ROOT))) {
                hits.add(word);
                if (hits.size() >= 5) {
                    break;
                }
            }
        }
        return hits;
    }

    public void invalidate(String region) {
        if (region != null) {
            cache.remove(region);
        }
    }

    public void invalidateAll() {
        cache.clear();
    }

    private List<String> enabledWords(String region) {
        CacheEntry cached = cache.get(region);
        long now = System.currentTimeMillis();
        if (cached != null && cached.expiresAtMs() > now) {
            return cached.words();
        }
        List<String> words = mapper.selectEnabledWords(region);
        List<String> normalized = words == null ? List.of() : List.copyOf(words);
        cache.put(region, new CacheEntry(normalized, now + 30_000L));
        return normalized;
    }

    private record CacheEntry(List<String> words, long expiresAtMs) {
    }
}
