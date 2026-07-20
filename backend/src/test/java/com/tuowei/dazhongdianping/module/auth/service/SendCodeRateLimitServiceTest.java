package com.tuowei.dazhongdianping.module.auth.service;

import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.config.SendCodeRateLimitProperties;
import java.util.Collections;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

class SendCodeRateLimitServiceTest {

    @Test
    void shouldUseRedisSortedSetsWhenStateStoreProviderIsRedis() {
        SendCodeRateLimitProperties rateLimitProperties = new SendCodeRateLimitProperties();
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ZSetOperations<String, String> zSetOperations = mock(ZSetOperations.class);
        when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);
        when(zSetOperations.count(anyString(), anyDouble(), anyDouble())).thenReturn(0L);
        when(zSetOperations.rangeByScoreWithScores(anyString(), anyDouble(), anyDouble(), eq(0L), eq(1L)))
                .thenReturn(Collections.emptySet());

        SendCodeRateLimitService service = new SendCodeRateLimitService(
                rateLimitProperties,
                infrastructureProperties,
                providerOf(redisTemplate)
        );

        service.checkAndRecord("login", 1, "redis@example.com", "device-redis", "127.0.0.1");

        verify(zSetOperations, times(3)).add(anyString(), anyString(), anyDouble());
        verify(redisTemplate, times(3)).expire(anyString(), org.mockito.ArgumentMatchers.any(java.time.Duration.class));
    }

    private ObjectProvider<StringRedisTemplate> providerOf(StringRedisTemplate redisTemplate) {
        return new ObjectProvider<>() {
            @Override
            public StringRedisTemplate getObject(Object... args) {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfAvailable() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfUnique() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getObject() {
                return redisTemplate;
            }
        };
    }
}
