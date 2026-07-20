package com.tuowei.dazhongdianping.module.auth.service;

import static java.util.concurrent.TimeUnit.SECONDS;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.UserSessionRow;
import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthLoginCodeRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthSessionResponse;
import com.tuowei.dazhongdianping.module.social.service.SocialService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class PublicAuthServiceConcurrencyTest {

    @Autowired
    private AuthCommandMapper databaseMapper;

    @Autowired
    private PublicAuthService databaseAuthService;

    @Test
    void shouldRejectOlderVerificationCodeWhenNewerCodeWasIssued() {
        String account = uniqueEmail("latest-code");
        databaseMapper.insertVerificationCode(verificationCode(account, "123456"));
        databaseMapper.insertVerificationCode(verificationCode(account, "654321"));

        AuthLoginCodeRequest request = loginCodeRequest(account, "123456");

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> databaseAuthService.loginWithCode(request)
        );
        assertEquals("验证码无效或已过期", exception.getMessage());
    }

    @Test
    void shouldNotFallBackToOlderVerificationCodeAfterLatestWasConsumed() {
        String account = uniqueEmail("consumed-latest-code");
        databaseMapper.insertVerificationCode(verificationCode(account, "123456"));
        databaseMapper.insertVerificationCode(verificationCode(account, "123456"));
        AuthLoginCodeRequest request = loginCodeRequest(account, "123456");

        databaseAuthService.loginWithCode(request);

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> databaseAuthService.loginWithCode(request)
        );
        assertEquals("验证码无效或已过期", exception.getMessage());
    }

    @Test
    void shouldAllowOnlyOneConcurrentConsumerForSameVerificationCode() throws Exception {
        AuthCommandMapper authCommandMapper = mock(AuthCommandMapper.class);
        SendCodeRateLimitService sendCodeRateLimitService = mock(SendCodeRateLimitService.class);
        UserPrivacyService userPrivacyService = mock(UserPrivacyService.class);
        SocialService socialService = mock(SocialService.class);
        UserAccessTokenService userAccessTokenService = mock(UserAccessTokenService.class);
        PublicAuthService publicAuthService = new PublicAuthService(
                authCommandMapper,
                sendCodeRateLimitService,
                userPrivacyService,
                socialService,
                userAccessTokenService,
                2_592_000
        );

        AppUserRow user = new AppUserRow();
        user.setId(100L);
        user.setEmail("concurrent@example.com");
        user.setNickname("并发用户");
        user.setAvatar("");
        user.setPreferredRegion("CN");
        user.setStatus(1);

        VerificationCodeRow verificationCode = new VerificationCodeRow();
        verificationCode.setId(200L);
        verificationCode.setCodeHash(sha256Hex("123456"));
        verificationCode.setStatus(0);
        verificationCode.setExpireAt(LocalDateTime.now().plusMinutes(5));

        CyclicBarrier bothSelected = new CyclicBarrier(2);
        AtomicBoolean consumed = new AtomicBoolean();
        AtomicLong sessionIds = new AtomicLong(300L);
        when(authCommandMapper.selectLatestVerificationCode(anyString(), anyInt(), anyString()))
                .thenAnswer(invocation -> {
                    bothSelected.await(5, SECONDS);
                    return verificationCode;
                });
        when(authCommandMapper.selectUserByEmail("concurrent@example.com")).thenReturn(user);
        when(authCommandMapper.markVerificationCodeUsed(200L))
                .thenAnswer(invocation -> consumed.compareAndSet(false, true) ? 1 : 0);
        doAnswer(invocation -> {
            UserSessionRow row = invocation.getArgument(0);
            row.setId(sessionIds.getAndIncrement());
            return null;
        }).when(authCommandMapper).insertUserSession(any(UserSessionRow.class));
        when(userAccessTokenService.issue(anyLong(), anyLong())).thenReturn("access-token");

        AuthLoginCodeRequest request = new AuthLoginCodeRequest();
        request.setType("email");
        request.setAccount("concurrent@example.com");
        request.setCode("123456");

        ExecutorService executorService = Executors.newFixedThreadPool(2);
        try {
            Future<Object> first = executorService.submit(() -> login(publicAuthService, request));
            Future<Object> second = executorService.submit(() -> login(publicAuthService, request));
            List<Object> results = List.of(first.get(5, SECONDS), second.get(5, SECONDS));

            assertEquals(1, results.stream().filter(AuthSessionResponse.class::isInstance).count());
            Object failure = results.stream()
                    .filter(IllegalArgumentException.class::isInstance)
                    .findFirst()
                    .orElseThrow();
            IllegalArgumentException exception = assertInstanceOf(IllegalArgumentException.class, failure);
            assertEquals("验证码无效或已过期", exception.getMessage());
            verify(authCommandMapper).insertUserSession(any(UserSessionRow.class));
        } finally {
            executorService.shutdownNow();
        }
    }

    private Object login(PublicAuthService publicAuthService, AuthLoginCodeRequest request) {
        try {
            return publicAuthService.loginWithCode(request);
        } catch (RuntimeException exception) {
            return exception;
        }
    }

    private AuthLoginCodeRequest loginCodeRequest(String account, String code) {
        AuthLoginCodeRequest request = new AuthLoginCodeRequest();
        request.setType("email");
        request.setAccount(account);
        request.setCode(code);
        return request;
    }

    private VerificationCodeRow verificationCode(String target, String code) {
        VerificationCodeRow row = new VerificationCodeRow();
        row.setScene("login");
        row.setTargetType(1);
        row.setTarget(target);
        row.setCodeHash(sha256Hex(code));
        row.setDeviceId("concurrency-test");
        row.setRequestIp("127.0.0.1");
        row.setStatus(0);
        row.setExpireAt(LocalDateTime.now().plusMinutes(5));
        return row;
    }

    private String uniqueEmail(String prefix) {
        return prefix + "-" + UUID.randomUUID() + "@example.com";
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(messageDigest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }
}
