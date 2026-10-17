package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 广告点击去重：同一 (区域, 广告, 访客) 在时间窗内只允许计费一次，防止脚本刷点击耗尽竞对日预算。
 * 访客标识优先用登录 userId，匿名时退化为客户端 IP；两者都会先转成带密钥的短期指纹。
 * 原始 IP 只在请求内存中使用，不写业务表、Redis 键或告警日志。
 * 状态存储跟随 app.infrastructure.state-store（pre/prod 强制 redis，多节点共享）。
 * Redis 异常时 fail-closed：宁可漏计一次点击，也不放开重复计费。
 */
@Component
public class AdClickDeduplicator {

    private static final Logger log = LoggerFactory.getLogger(AdClickDeduplicator.class);
    private static final String TEST_ONLY_HMAC_SECRET = "ad-click-dedupe-test-key-not-for-runtime";
    private static final String HMAC_KEY_CONTEXT = "dazhongdianping/ad-click-dedupe/key/v1";
    private static final DefaultRedisScript<Long> RELEASE_IF_OWNED = new DefaultRedisScript<>(
            "if redis.call('get', KEYS[1]) == ARGV[1] then "
                    + "return redis.call('del', KEYS[1]) else return 0 end",
            Long.class);

    private final InfrastructureProperties infrastructureProperties;
    private final StringRedisTemplate redisTemplate;
    private final Duration window;
    private final Clock clock;
    private final SecretKeySpec viewerHmacKey;
    private final Map<String, LocalClaim> localSeen = new ConcurrentHashMap<>();

    public record Acquisition(String key, String token, boolean redisBacked) {}

    private record LocalClaim(String token, Instant expiresAt) {}

    @Autowired
    public AdClickDeduplicator(InfrastructureProperties infrastructureProperties,
                               ObjectProvider<StringRedisTemplate> redisTemplateProvider,
                               @Value("${app.ad.click-dedupe-seconds:1800}") long windowSeconds,
                               @Value("${app.auth.jwt-secret}") String keyDerivationSecret) {
        this(infrastructureProperties, redisTemplateProvider.getIfAvailable(),
                Duration.ofSeconds(Math.max(1L, windowSeconds)), Clock.systemUTC(), keyDerivationSecret);
    }

    AdClickDeduplicator(InfrastructureProperties infrastructureProperties,
                        StringRedisTemplate redisTemplate,
                        Duration window,
                        Clock clock) {
        this(infrastructureProperties, redisTemplate, window, clock, TEST_ONLY_HMAC_SECRET);
    }

    private AdClickDeduplicator(InfrastructureProperties infrastructureProperties,
                                StringRedisTemplate redisTemplate,
                                Duration window,
                                Clock clock,
                                String keyDerivationSecret) {
        this.infrastructureProperties = infrastructureProperties;
        this.redisTemplate = redisTemplate;
        this.window = window;
        this.clock = clock;
        this.viewerHmacKey = deriveViewerHmacKey(keyDerivationSecret);
    }

    /**
     * 尝试占用本次点击的计费资格。
     *
     * @return true 表示时间窗内首次点击、可以计费；false 表示重复点击或去重存储不可用
     */
    public boolean tryAcquire(String region, Long campaignId, long userId, String clientIp) {
        return acquire(region, campaignId, userId, clientIp).isPresent();
    }

    /** Returns an owned claim so callers can release it if the billing transaction rolls back. */
    public Optional<Acquisition> acquire(String region, Long campaignId, long userId, String clientIp) {
        String viewer = viewerKey(userId, clientIp);
        String suffix = "ad_click:" + region + ":" + campaignId + ":" + viewer;
        String token = UUID.randomUUID().toString();
        if (useRedis()) {
            if (redisTemplate == null) {
                log.warn("广告点击去重缺少 Redis 客户端，本次不计费 campaign={}", campaignId);
                return Optional.empty();
            }
            String key = redisKey(suffix);
            try {
                return Boolean.TRUE.equals(redisTemplate.opsForValue().setIfAbsent(key, token, window))
                        ? Optional.of(new Acquisition(key, token, true))
                        : Optional.empty();
            } catch (RuntimeException ex) {
                log.warn("广告点击去重存储不可用，本次不计费 campaign={} region={} cause={}",
                        campaignId, region, ex.getClass().getSimpleName());
                return Optional.empty();
            }
        }
        return tryAcquireLocal(suffix, token);
    }

    /** Releases only the claim created by this request. */
    public void release(Acquisition acquisition) {
        if (acquisition == null) {
            return;
        }
        if (acquisition.redisBacked()) {
            try {
                redisTemplate.execute(RELEASE_IF_OWNED, java.util.List.of(acquisition.key()), acquisition.token());
            } catch (RuntimeException ex) {
                log.warn("广告点击去重回滚释放失败，本次 claim 将在 TTL 后过期 cause={}",
                        ex.getClass().getSimpleName());
            }
            return;
        }
        localSeen.computeIfPresent(acquisition.key(), (key, claim) ->
                claim.token().equals(acquisition.token()) ? null : claim);
    }

    /** 测试用：清空去重状态。 */
    public void clearAll() {
        localSeen.clear();
    }

    private Optional<Acquisition> tryAcquireLocal(String key, String token) {
        Instant now = Instant.now(clock);
        LocalClaim[] acquired = {null};
        localSeen.compute(key, (k, claim) -> {
            if (claim == null || !claim.expiresAt().isAfter(now)) {
                LocalClaim replacement = new LocalClaim(token, now.plus(window));
                acquired[0] = replacement;
                return replacement;
            }
            return claim;
        });
        return acquired[0] == null
                ? Optional.empty()
                : Optional.of(new Acquisition(key, token, false));
    }

    @Scheduled(fixedDelayString = "${app.ad.click-dedupe-cleanup-ms:60000}")
    public void sweepExpiredLocalState() {
        if (!useRedis() && !localSeen.isEmpty()) {
            sweepExpired(Instant.now(clock));
        }
    }

    private void sweepExpired(Instant now) {
        localSeen.forEach((key, claim) -> {
            if (!claim.expiresAt().isAfter(now)) {
                localSeen.remove(key, claim);
            }
        });
    }

    private String viewerKey(long userId, String clientIp) {
        if (userId > 0) {
            return "u" + fingerprint("user/v1/" + userId);
        }
        return "ip" + fingerprint("ip/v1/" + (StringUtils.hasText(clientIp) ? clientIp.trim() : "unknown"));
    }

    private String fingerprint(String viewer) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(viewerHmacKey);
            return HexFormat.of().formatHex(mac.doFinal(viewer.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("广告点击去重指纹计算失败", ex);
        }
    }

    private static SecretKeySpec deriveViewerHmacKey(String keyDerivationSecret) {
        if (!StringUtils.hasText(keyDerivationSecret)) {
            throw new IllegalStateException("广告点击去重指纹密钥不能为空");
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(keyDerivationSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] key = mac.doFinal(HMAC_KEY_CONTEXT.getBytes(StandardCharsets.UTF_8));
            return new SecretKeySpec(key, "HmacSHA256");
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("广告点击去重指纹密钥初始化失败", ex);
        }
    }

    private boolean useRedis() {
        return infrastructureProperties.getStateStore().getProvider()
                == InfrastructureProperties.StateStoreProvider.REDIS;
    }

    private String redisKey(String suffix) {
        String prefix = infrastructureProperties.getStateStore().getKeyPrefix();
        return (StringUtils.hasText(prefix) ? prefix : "dzdp") + ":" + suffix;
    }
}
