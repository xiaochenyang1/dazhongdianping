package com.tuowei.dazhongdianping.module.adpromo.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import org.mockito.ArgumentCaptor;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

class AdClickDeduplicatorTest {

    private static final Duration WINDOW = Duration.ofMinutes(30);

    /** 可拨动的测试时钟。 */
    private static final class MutableClock extends Clock {
        private Instant now = Instant.parse("2026-10-01T00:00:00Z");

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    private InfrastructureProperties provider(InfrastructureProperties.StateStoreProvider p) {
        InfrastructureProperties props = new InfrastructureProperties();
        props.getStateStore().setProvider(p);
        return props;
    }

    @Test
    void localStoreChargesOncePerViewerWithinWindow() {
        MutableClock clock = new MutableClock();
        AdClickDeduplicator dedup = new AdClickDeduplicator(
                provider(InfrastructureProperties.StateStoreProvider.LOCAL), null, WINDOW, clock);

        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isTrue();
        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isFalse();
        // 不同访客 / 不同广告互不影响
        assertThat(dedup.tryAcquire("CN", 1L, 0L, "5.6.7.8")).isTrue();
        assertThat(dedup.tryAcquire("CN", 2L, 0L, "1.2.3.4")).isTrue();
        // 登录用户按 userId 去重，换 IP 也不能重复计费
        assertThat(dedup.tryAcquire("CN", 1L, 42L, "9.9.9.9")).isTrue();
        assertThat(dedup.tryAcquire("CN", 1L, 42L, "8.8.8.8")).isFalse();

        // 窗口过后可再次计费
        clock.now = clock.now.plus(WINDOW).plusSeconds(1);
        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isTrue();
    }

    @Test
    void redisStoreUsesSetIfAbsentWithWindowTtl() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> ops = mock(ValueOperations.class);
        when(redis.opsForValue()).thenReturn(ops);
        when(ops.setIfAbsent(anyString(), anyString(), eq(WINDOW)))
                .thenReturn(true, false);

        AdClickDeduplicator dedup = new AdClickDeduplicator(
                provider(InfrastructureProperties.StateStoreProvider.REDIS), redis, WINDOW, Clock.systemUTC());

        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isTrue();
        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isFalse();
        ArgumentCaptor<String> redisKeys = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> claimTokens = ArgumentCaptor.forClass(String.class);
        verify(ops, times(2)).setIfAbsent(redisKeys.capture(), claimTokens.capture(), eq(WINDOW));
        assertThat(redisKeys.getAllValues()).containsOnly(redisKeys.getAllValues().get(0));
        assertThat(redisKeys.getAllValues().get(0)).startsWith("dzdp:ad_click:CN:1:ip").doesNotContain("1.2.3.4");
        assertThat(claimTokens.getAllValues()).allMatch(token -> token != null && !token.isBlank()).doesNotHaveDuplicates();
    }

    @Test
    void redisFailureFailsClosedAndDoesNotCharge() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> ops = mock(ValueOperations.class);
        when(redis.opsForValue()).thenReturn(ops);
        when(ops.setIfAbsent(anyString(), anyString(), any(Duration.class)))
                .thenThrow(new IllegalStateException("redis down"));

        AdClickDeduplicator dedup = new AdClickDeduplicator(
                provider(InfrastructureProperties.StateStoreProvider.REDIS), redis, WINDOW, Clock.systemUTC());

        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isFalse();
    }

    @Test
    void missingRedisClientDoesNotFallBackToPerInstanceDedupe() {
        AdClickDeduplicator dedup = new AdClickDeduplicator(
                provider(InfrastructureProperties.StateStoreProvider.REDIS), null, WINDOW, Clock.systemUTC());

        assertThat(dedup.tryAcquire("CN", 1L, 0L, "1.2.3.4")).isFalse();
        assertThat(dedup.tryAcquire("CN", 1L, 42L, "1.2.3.4")).isFalse();
    }
}
