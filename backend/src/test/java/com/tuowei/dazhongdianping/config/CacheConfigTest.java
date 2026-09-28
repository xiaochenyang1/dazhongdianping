package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.cache.CacheManager;

class CacheConfigTest {

    @Test
    void cacheManagerExposesConfiguredHotReadCaches() {
        CacheManager cacheManager = new CacheConfig().cacheManager();

        assertThat(cacheManager.getCache(CacheConfig.HOME_BANNERS)).isNotNull();
        assertThat(cacheManager.getCache(CacheConfig.RANK_LIST)).isNotNull();
        assertThat(cacheManager.getCache(CacheConfig.RANK_DETAIL)).isNotNull();
    }

    @Test
    void cacheManagerStoresAndReturnsValues() {
        CacheManager cacheManager = new CacheConfig().cacheManager();

        cacheManager.getCache(CacheConfig.RANK_LIST).put("k", "v");

        assertThat(cacheManager.getCache(CacheConfig.RANK_LIST).get("k").get()).isEqualTo("v");
    }
}
