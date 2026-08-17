package com.tuowei.dazhongdianping.config;

import java.net.URI;
import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class ApplicationSafetyValidator implements InitializingBean {

    static final String LOCAL_JWT_SECRET = "local-dev-auth-secret-please-change";
    static final String LOCAL_PAYMENT_SECRET = "local-payment-notify-secret-please-change";
    private static final Set<String> RUNTIME_MODES = Set.of("local", "test", "pre", "prod");

    private final String runtimeMode;
    private final String jwtSecret;
    private final String paymentNotifySecret;
    private final boolean paymentMockEnabled;
    private final VerificationCodeProperties verificationCode;
    private final boolean strictSpringProfile;
    private final boolean matchingDevelopmentSpringProfile;
    private final CorsProperties corsProperties;

    public ApplicationSafetyValidator(
            Environment environment,
            @Value("${app.runtime-mode:prod}") String runtimeMode,
            @Value("${app.auth.jwt-secret:}") String jwtSecret,
            @Value("${app.payment.notify-secret:}") String paymentNotifySecret,
            @Value("${app.payment.mock-enabled:false}") boolean paymentMockEnabled,
            VerificationCodeProperties verificationCode,
            CorsProperties corsProperties) {
        this.runtimeMode = runtimeMode == null ? "" : runtimeMode.trim().toLowerCase(Locale.ROOT);
        this.jwtSecret = jwtSecret == null ? "" : jwtSecret.trim();
        this.paymentNotifySecret = paymentNotifySecret == null ? "" : paymentNotifySecret.trim();
        this.paymentMockEnabled = paymentMockEnabled;
        this.verificationCode = verificationCode;
        this.corsProperties = corsProperties;
        this.strictSpringProfile = Arrays.stream(environment.getActiveProfiles())
                .map(profile -> profile.toLowerCase(Locale.ROOT))
                .anyMatch(profile -> "pre".equals(profile) || "prod".equals(profile));
        this.matchingDevelopmentSpringProfile = Arrays.stream(environment.getActiveProfiles())
                .map(profile -> profile.toLowerCase(Locale.ROOT))
                .anyMatch(profile -> this.runtimeMode.equals(profile));
    }

    @Override
    public void afterPropertiesSet() {
        if (!RUNTIME_MODES.contains(runtimeMode)) {
            throw new IllegalStateException("APP_RUNTIME_MODE must be one of local, test, pre, or prod");
        }
        if (isDevelopmentMode() && !strictSpringProfile && !matchingDevelopmentSpringProfile) {
            throw new IllegalStateException("local/test runtime mode requires the matching Spring profile");
        }
        requireStrongSecret("APP_AUTH_JWT_SECRET", jwtSecret);
        requireStrongSecret("APP_PAYMENT_NOTIFY_SECRET", paymentNotifySecret);
        validateVerificationCode();

        if (isStrictMode()) {
            if (LOCAL_JWT_SECRET.equals(jwtSecret) || LOCAL_PAYMENT_SECRET.equals(paymentNotifySecret)) {
                throw new IllegalStateException("pre/prod cannot use repository development secrets");
            }
            if (paymentMockEnabled) {
                throw new IllegalStateException("APP_PAYMENT_MOCK_ENABLED must be false in pre/prod");
            }
            if (verificationCode.isMockEnabled() || verificationCode.isExposeMockCode()) {
                throw new IllegalStateException("mock verification codes must be disabled in pre/prod");
            }
            if (verificationCode.isDevConsoleEnabled()) {
                throw new IllegalStateException(
                        "APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED must be false in pre/prod");
            }
        }

        validateCorsOrigins();
    }

    private void validateVerificationCode() {
        if (verificationCode.isExposeMockCode() && !verificationCode.isMockEnabled()) {
            throw new IllegalStateException("mock verification code exposure requires mock mode");
        }
        if (verificationCode.isMockEnabled()
                && (!StringUtils.hasText(verificationCode.getMockCode())
                || !verificationCode.getMockCode().trim().matches("\\d{6}"))) {
            throw new IllegalStateException("APP_AUTH_VERIFICATION_MOCK_CODE must contain exactly six digits");
        }
        if (verificationCode.getMail().isEnabled() && !verificationCode.getMail().isConfigured()) {
            throw new IllegalStateException(
                    "enabled verification mail requires APP_MAIL_HOST, APP_AUTH_VERIFICATION_MAIL_FROM and subject");
        }
        if (verificationCode.getTwilio().isEnabled() && !verificationCode.getTwilio().isConfigured()) {
            throw new IllegalStateException(
                    "enabled Twilio verification requires account SID, auth token, and sender configuration");
        }
        if (verificationCode.getAliyun().isEnabled() && !verificationCode.getAliyun().isConfigured()) {
            throw new IllegalStateException(
                    "enabled Aliyun SMS verification requires access key, sign name, template code, and route prefixes");
        }
    }

    private boolean isStrictMode() {
        return strictSpringProfile || "pre".equals(runtimeMode) || "prod".equals(runtimeMode);
    }

    private void validateCorsOrigins() {
        if (corsProperties.getAllowedOriginPatterns() == null
                || corsProperties.getAllowedOriginPatterns().isEmpty()) {
            throw new IllegalStateException("APP_CORS_ALLOWED_ORIGIN_PATTERNS must contain at least one origin");
        }
        for (String origin : corsProperties.getAllowedOriginPatterns()) {
            if (!StringUtils.hasText(origin) || origin.matches(".*\\s+.*") || "*".equals(origin)) {
                throw new IllegalStateException("APP_CORS_ALLOWED_ORIGIN_PATTERNS contains an invalid origin");
            }
            if (isStrictMode()) {
                validateStrictCorsOrigin(origin);
            }
        }
    }

    private void validateStrictCorsOrigin(String origin) {
        try {
            URI uri = URI.create(origin);
            String host = uri.getHost();
            boolean invalid = !"https".equalsIgnoreCase(uri.getScheme())
                    || !StringUtils.hasText(host)
                    || uri.getUserInfo() != null
                    || StringUtils.hasText(uri.getPath())
                    || uri.getQuery() != null
                    || uri.getFragment() != null
                    || uri.getPort() == 0
                    || uri.getPort() > 65535
                    || origin.contains("*")
                    || "localhost".equalsIgnoreCase(host)
                    || "127.0.0.1".equals(host)
                    || "::1".equals(host)
                    || "[::1]".equals(host);
            if (invalid) {
                throw new IllegalStateException(
                        "pre/prod CORS origins must be explicit HTTPS origins without paths or local hosts");
            }
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                    "pre/prod CORS origins must be explicit HTTPS origins without paths or local hosts",
                    exception);
        }
    }

    private boolean isDevelopmentMode() {
        return "local".equals(runtimeMode) || "test".equals(runtimeMode);
    }

    private void requireStrongSecret(String name, String value) {
        if (!StringUtils.hasText(value) || value.length() < 32) {
            throw new IllegalStateException(name + " must contain at least 32 characters");
        }
    }
}
