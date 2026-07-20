package com.tuowei.dazhongdianping.module.merchant.auth.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantOperatorRow;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class MerchantAuthService {

    private final Map<String, StoredMerchantSession> sessionStore = new ConcurrentHashMap<>();

    private final MerchantIdentityMapper merchantIdentityMapper;
    private final PasswordEncoder passwordEncoder;
    private final long accessTokenExpireSeconds;

    public MerchantAuthService(MerchantIdentityMapper merchantIdentityMapper,
                               @Value("${app.merchant.access-token-expire-seconds}") long accessTokenExpireSeconds) {
        this.merchantIdentityMapper = merchantIdentityMapper;
        this.passwordEncoder = new BCryptPasswordEncoder();
        this.accessTokenExpireSeconds = accessTokenExpireSeconds;
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
                operator.getOperatorType()
        );
        return issueSession(session);
    }

    public MerchantLoginResult issueSession(MerchantSession session) {
        String token = UUID.randomUUID().toString().replace("-", "");
        sessionStore.put(token, new StoredMerchantSession(
                session,
                Instant.now().plusSeconds(accessTokenExpireSeconds)
        ));
        return new MerchantLoginResult(token, session);
    }

    public MerchantSession authenticate(String token) {
        StoredMerchantSession storedSession = sessionStore.get(token);
        if (storedSession == null) {
            throw new UnauthorizedException("商户登录已失效，请重新登录");
        }
        if (!storedSession.expiresAt().isAfter(Instant.now())) {
            sessionStore.remove(token, storedSession);
            throw new UnauthorizedException("商户登录已过期，请重新登录");
        }
        MerchantOperatorRow operator = merchantIdentityMapper.selectOperatorById(storedSession.session().operatorId());
        if (operator == null || operator.getOperatorStatus() != 1 || operator.getMerchantStatus() != 1) {
            sessionStore.remove(token, storedSession);
            throw new UnauthorizedException("商户登录已失效，请重新登录");
        }
        return storedSession.session();
    }

    public record MerchantLoginResult(
            String accessToken,
            MerchantSession session
    ) {
    }

    private record StoredMerchantSession(
            MerchantSession session,
            Instant expiresAt
    ) {
    }
}
