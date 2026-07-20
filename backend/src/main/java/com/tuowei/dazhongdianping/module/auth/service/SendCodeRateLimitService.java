package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.common.api.RateLimitException;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.config.SendCodeRateLimitProperties;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

@Service
public class SendCodeRateLimitService {

    private final SendCodeRateLimitProperties properties;
    private final InfrastructureProperties infrastructureProperties;
    private final StringRedisTemplate redisTemplate;
    private final Clock clock = Clock.systemUTC();
    private final Map<String, Deque<Instant>> buckets = new HashMap<>();

    public SendCodeRateLimitService(SendCodeRateLimitProperties properties,
                                    InfrastructureProperties infrastructureProperties,
                                    ObjectProvider<StringRedisTemplate> redisTemplateProvider) {
        this.properties = properties;
        this.infrastructureProperties = infrastructureProperties;
        this.redisTemplate = redisTemplateProvider.getIfAvailable();
    }

    public synchronized void checkAndRecord(String scene,
                                            int targetType,
                                            String account,
                                            String deviceId,
                                            String requestIp) {
        Instant now = Instant.now(clock);
        List<SubjectCheck> checks = new ArrayList<>();
        checks.add(new SubjectCheck(
                "send_code:account:" + scene + ":" + targetType + ":" + account,
                List.of(
                        new WindowRule(properties.getAccountShortWindowSeconds(), properties.getAccountShortWindowMaxRequests()),
                        new WindowRule(properties.getAccountLongWindowSeconds(), properties.getAccountLongWindowMaxRequests())
                )
        ));
        if (StringUtils.hasText(deviceId)) {
            checks.add(new SubjectCheck(
                    "send_code:device:" + deviceId.trim(),
                    List.of(new WindowRule(properties.getDeviceWindowSeconds(), properties.getDeviceWindowMaxRequests()))
            ));
        }
        if (StringUtils.hasText(requestIp)) {
            checks.add(new SubjectCheck(
                    "send_code:ip:" + requestIp.trim(),
                    List.of(new WindowRule(properties.getIpWindowSeconds(), properties.getIpWindowMaxRequests()))
            ));
        }

        if (useRedis()) {
            checkAndRecordInRedis(checks, now);
            return;
        }

        long retryAfterSeconds = 0L;
        for (SubjectCheck check : checks) {
            long subjectRetryAfterSeconds = evaluateRetryAfter(check, now);
            if (subjectRetryAfterSeconds > retryAfterSeconds) {
                retryAfterSeconds = subjectRetryAfterSeconds;
            }
        }
        if (retryAfterSeconds > 0L) {
            throw new RateLimitException("验证码发送太频繁，请稍后再试", retryAfterSeconds);
        }

        for (SubjectCheck check : checks) {
            Deque<Instant> bucket = buckets.computeIfAbsent(check.key(), ignored -> new ArrayDeque<>());
            pruneBucket(bucket, now, check.maxWindowSeconds());
            bucket.addLast(now);
        }
    }

    public synchronized void clearAll() {
        buckets.clear();
        if (useRedis()) {
            Set<String> keys = redisTemplate.keys(redisKey("*"));
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
            }
        }
    }

    private void checkAndRecordInRedis(List<SubjectCheck> checks, Instant now) {
        long retryAfterSeconds = 0L;
        for (SubjectCheck check : checks) {
            long subjectRetryAfterSeconds = evaluateRedisRetryAfter(check, now);
            if (subjectRetryAfterSeconds > retryAfterSeconds) {
                retryAfterSeconds = subjectRetryAfterSeconds;
            }
        }
        if (retryAfterSeconds > 0L) {
            throw new RateLimitException("验证码发送太频繁，请稍后再试", retryAfterSeconds);
        }

        String member = now.toEpochMilli() + ":" + java.util.UUID.randomUUID();
        for (SubjectCheck check : checks) {
            String key = redisKey(check.key());
            redisTemplate.opsForZSet().removeRangeByScore(key, 0, now.minusSeconds(check.maxWindowSeconds()).toEpochMilli());
            redisTemplate.opsForZSet().add(key, member, now.toEpochMilli());
            redisTemplate.expire(key, Duration.ofSeconds(check.maxWindowSeconds()));
        }
    }

    private long evaluateRedisRetryAfter(SubjectCheck check, Instant now) {
        String key = redisKey(check.key());
        ZSetOperations<String, String> zSetOperations = redisTemplate.opsForZSet();
        zSetOperations.removeRangeByScore(key, 0, now.minusSeconds(check.maxWindowSeconds()).toEpochMilli());

        long retryAfterSeconds = 0L;
        for (WindowRule rule : check.rules()) {
            long windowStart = now.minusSeconds(rule.windowSeconds()).toEpochMilli();
            Long count = zSetOperations.count(key, windowStart, now.toEpochMilli());
            if (count == null || count < rule.maxRequests()) {
                continue;
            }

            Set<ZSetOperations.TypedTuple<String>> oldestValues =
                    zSetOperations.rangeByScoreWithScores(key, windowStart, now.toEpochMilli(), 0, 1);
            if (oldestValues == null || oldestValues.isEmpty()) {
                continue;
            }

            Double score = oldestValues.iterator().next().getScore();
            if (score == null) {
                continue;
            }
            long currentRetryAfter = ceilToSeconds(Duration.between(now, Instant.ofEpochMilli(score.longValue()).plusSeconds(rule.windowSeconds())));
            if (currentRetryAfter > retryAfterSeconds) {
                retryAfterSeconds = currentRetryAfter;
            }
        }
        return retryAfterSeconds;
    }

    private boolean useRedis() {
        return infrastructureProperties.getStateStore().getProvider() == InfrastructureProperties.StateStoreProvider.REDIS
                && redisTemplate != null;
    }

    private String redisKey(String suffix) {
        String prefix = infrastructureProperties.getStateStore().getKeyPrefix();
        if (!StringUtils.hasText(prefix)) {
            prefix = "dzdp";
        }
        return prefix + ":" + suffix;
    }

    private long evaluateRetryAfter(SubjectCheck check, Instant now) {
        Deque<Instant> bucket = buckets.computeIfAbsent(check.key(), ignored -> new ArrayDeque<>());
        pruneBucket(bucket, now, check.maxWindowSeconds());
        if (bucket.isEmpty()) {
            buckets.remove(check.key());
            return 0L;
        }

        long retryAfterSeconds = 0L;
        for (WindowRule rule : check.rules()) {
            Instant windowStart = now.minusSeconds(rule.windowSeconds());
            int count = 0;
            Instant oldestInWindow = null;
            for (Instant instant : bucket) {
                if (!instant.isAfter(windowStart)) {
                    continue;
                }
                if (oldestInWindow == null) {
                    oldestInWindow = instant;
                }
                count += 1;
            }
            if (count >= rule.maxRequests() && oldestInWindow != null) {
                long currentRetryAfter = ceilToSeconds(Duration.between(now, oldestInWindow.plusSeconds(rule.windowSeconds())));
                if (currentRetryAfter > retryAfterSeconds) {
                    retryAfterSeconds = currentRetryAfter;
                }
            }
        }
        return retryAfterSeconds;
    }

    private void pruneBucket(Deque<Instant> bucket, Instant now, int maxWindowSeconds) {
        Instant threshold = now.minusSeconds(maxWindowSeconds);
        while (!bucket.isEmpty() && !bucket.peekFirst().isAfter(threshold)) {
            bucket.removeFirst();
        }
    }

    private long ceilToSeconds(Duration duration) {
        long milliseconds = Math.max(0L, duration.toMillis());
        if (milliseconds == 0L) {
            return 1L;
        }
        return Math.max(1L, (milliseconds + 999L) / 1000L);
    }

    private record WindowRule(int windowSeconds, int maxRequests) {
    }

    private record SubjectCheck(String key, List<WindowRule> rules) {

        int maxWindowSeconds() {
            int value = 0;
            for (WindowRule rule : rules) {
                value = Math.max(value, rule.windowSeconds());
            }
            return value;
        }
    }
}
