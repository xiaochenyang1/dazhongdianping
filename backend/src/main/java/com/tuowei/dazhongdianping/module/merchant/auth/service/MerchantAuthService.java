package com.tuowei.dazhongdianping.module.merchant.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantOperatorRow;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class MerchantAuthService {

    private final Map<String, StoredMerchantSession> sessionStore = new ConcurrentHashMap<>();

    private final MerchantIdentityMapper merchantIdentityMapper;
    private final PasswordEncoder passwordEncoder;
    private final long accessTokenExpireSeconds;
    private final ObjectMapper objectMapper;
    private final InfrastructureProperties infrastructureProperties;
    private final StringRedisTemplate redisTemplate;

    public MerchantAuthService(MerchantIdentityMapper merchantIdentityMapper,
                               @Value("${app.merchant.access-token-expire-seconds}") long accessTokenExpireSeconds,
                               ObjectMapper objectMapper,
                               InfrastructureProperties infrastructureProperties,
                               ObjectProvider<StringRedisTemplate> redisTemplateProvider) {
        this.merchantIdentityMapper = merchantIdentityMapper;
        this.passwordEncoder = new BCryptPasswordEncoder();
        this.accessTokenExpireSeconds = accessTokenExpireSeconds;
        this.objectMapper = objectMapper;
        this.infrastructureProperties = infrastructureProperties;
        this.redisTemplate = redisTemplateProvider.getIfAvailable();
    }

    public MerchantLoginResult login(String account, String password) {
        MerchantOperatorRow operator = merchantIdentityMapper.selectOperatorByAccount(account.trim());
        if (operator == null
                || operator.getOperatorStatus() != 1
                || operator.getMerchantStatus() != 1
                || !passwordEncoder.matches(password, operator.getPasswordHash())) {
            throw new UnauthorizedException("商户账号或密码错误");
        }
        MerchantSession session = new MerchantSession(
                operator.getId(),
                operator.getMerchantId(),
                operator.getAccount(),
                operator.getOperatorType(),
                operator.getRegion()
        );
        return issueSession(session);
    }

    public MerchantLoginResult issueSession(MerchantSession session) {
        String token = UUID.randomUUID().toString().replace("-", "");
        putSession(token, new StoredMerchantSession(
                session,
                Instant.now().plusSeconds(accessTokenExpireSeconds)
        ));
        return new MerchantLoginResult(token, session);
    }

    public MerchantSession authenticate(String token) {
        StoredMerchantSession storedSession = readSession(token);
        if (storedSession == null) {
            throw new UnauthorizedException("商户登录已失效，请重新登录");
        }
        if (!storedSession.expiresAt().isAfter(Instant.now())) {
            removeSession(token);
            throw new UnauthorizedException("商户登录已过期，请重新登录");
        }
        MerchantOperatorRow operator = merchantIdentityMapper.selectOperatorById(storedSession.session().operatorId());
        if (operator == null
                || operator.getOperatorStatus() != 1
                || operator.getMerchantStatus() != 1
                || !storedSession.session().region().equals(operator.getRegion())) {
            removeSession(token);
            throw new UnauthorizedException("商户登录已失效，请重新登录");
        }
        return storedSession.session();
    }

    public record MerchantLoginResult(
            String accessToken,
            MerchantSession session
    ) {
    }

    /**
     * 会话存储采用与 {@code IdempotencyFilter} / {@code SendCodeRateLimitService} 相同的范式:
     * 当 state-store 配置为 Redis 且 RedisTemplate 可用时,会话落 Redis(重启不丢失、多节点可见);
     * 否则退回进程内 ConcurrentHashMap,保证单节点/开发/测试环境可用。
     */
    private void putSession(String token, StoredMerchantSession session) {
        if (useRedis()) {
            redisTemplate.opsForValue().set(redisKey(token), writeJson(session), Duration.ofSeconds(accessTokenExpireSeconds));
            return;
        }
        sessionStore.put(token, session);
    }

    private StoredMerchantSession readSession(String token) {
        if (useRedis()) {
            String json = redisTemplate.opsForValue().get(redisKey(token));
            if (!StringUtils.hasText(json)) {
                return null;
            }
            StoredMerchantSession session = readJson(json);
            if (session == null) {
                redisTemplate.delete(redisKey(token));
            }
            return session;
        }
        return sessionStore.get(token);
    }

    private void removeSession(String token) {
        if (useRedis()) {
            redisTemplate.delete(redisKey(token));
            return;
        }
        sessionStore.remove(token);
    }

    private boolean useRedis() {
        return infrastructureProperties.getStateStore().getProvider() == InfrastructureProperties.StateStoreProvider.REDIS
                && redisTemplate != null;
    }

    private String redisKey(String token) {
        String prefix = infrastructureProperties.getStateStore().getKeyPrefix();
        if (!StringUtils.hasText(prefix)) {
            prefix = "dzdp";
        }
        return prefix + ":merchant:session:" + token;
    }

    private String writeJson(StoredMerchantSession session) {
        try {
            return objectMapper.writeValueAsString(session);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to serialize merchant session", exception);
        }
    }

    private StoredMerchantSession readJson(String json) {
        try {
            return objectMapper.readValue(json, StoredMerchantSession.class);
        } catch (IOException exception) {
            return null;
        }
    }

    private record StoredMerchantSession(
            MerchantSession session,
            Instant expiresAt
    ) {
    }
}
