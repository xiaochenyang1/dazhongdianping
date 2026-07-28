package com.tuowei.dazhongdianping.config;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class ApplicationSafetyValidatorTest {

    private static final String STRONG_JWT_SECRET = "jwt-secret-for-runtime-safety-tests-001";
    private static final String STRONG_PAYMENT_SECRET = "payment-secret-for-runtime-safety-tests-001";

    @Test
    void shouldRejectMissingSecretsByDefault() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> validator("prod", "", "", false, verificationCode(false, "", false))
                        .afterPropertiesSet()
        );

        assertEquals("APP_AUTH_JWT_SECRET must contain at least 32 characters", exception.getMessage());
    }

    @Test
    void shouldAllowExplicitLocalMockConfiguration() {
        assertDoesNotThrow(() -> validator(
                "local",
                ApplicationSafetyValidator.LOCAL_JWT_SECRET,
                ApplicationSafetyValidator.LOCAL_PAYMENT_SECRET,
                true,
                verificationCode(true, "123456", true)
        ).afterPropertiesSet());
    }

    @Test
    void shouldRejectUnknownRuntimeMode() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "development",
                        STRONG_JWT_SECRET,
                        STRONG_PAYMENT_SECRET,
                        false,
                        verificationCode(false, "", false)
                ).afterPropertiesSet()
        );

        assertEquals("APP_RUNTIME_MODE must be one of local, test, pre, or prod", exception.getMessage());
    }

    @Test
    void shouldRejectLocalRuntimeWithoutMatchingSpringProfile() {
        ApplicationSafetyValidator validator = new ApplicationSafetyValidator(
                new MockEnvironment(),
                "local",
                STRONG_JWT_SECRET,
                STRONG_PAYMENT_SECRET,
                false,
                verificationCode(false, "", false)
        );

        IllegalStateException exception = assertThrows(IllegalStateException.class, validator::afterPropertiesSet);
        assertEquals("local/test runtime mode requires the matching Spring profile", exception.getMessage());
    }

    @Test
    void shouldRejectDevelopmentSecretsInStrictMode() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "prod",
                        ApplicationSafetyValidator.LOCAL_JWT_SECRET,
                        ApplicationSafetyValidator.LOCAL_PAYMENT_SECRET,
                        false,
                        verificationCode(false, "", false)
                ).afterPropertiesSet()
        );

        assertEquals("pre/prod cannot use repository development secrets", exception.getMessage());
    }

    @Test
    void shouldRejectMocksInStrictMode() {
        IllegalStateException paymentException = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "prod",
                        STRONG_JWT_SECRET,
                        STRONG_PAYMENT_SECRET,
                        true,
                        verificationCode(false, "", false)
                ).afterPropertiesSet()
        );
        assertEquals("APP_PAYMENT_MOCK_ENABLED must be false in pre/prod", paymentException.getMessage());

        IllegalStateException codeException = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "pre",
                        STRONG_JWT_SECRET,
                        STRONG_PAYMENT_SECRET,
                        false,
                        verificationCode(true, "123456", false)
                ).afterPropertiesSet()
        );
        assertEquals("mock verification codes must be disabled in pre/prod", codeException.getMessage());
    }

    @Test
    void shouldNotAllowProdProfileToBeDowngradedByRuntimeMode() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("prod");
        ApplicationSafetyValidator validator = new ApplicationSafetyValidator(
                environment,
                "local",
                STRONG_JWT_SECRET,
                STRONG_PAYMENT_SECRET,
                true,
                verificationCode(true, "123456", true)
        );

        IllegalStateException exception = assertThrows(IllegalStateException.class, validator::afterPropertiesSet);
        assertEquals("APP_PAYMENT_MOCK_ENABLED must be false in pre/prod", exception.getMessage());
    }

    @Test
    void shouldRejectInvalidMockCodeConfiguration() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "test",
                        STRONG_JWT_SECRET,
                        STRONG_PAYMENT_SECRET,
                        false,
                        verificationCode(true, "12345", false)
                ).afterPropertiesSet()
        );

        assertEquals("APP_AUTH_VERIFICATION_MOCK_CODE must contain exactly six digits", exception.getMessage());
    }

    @Test
    void shouldRejectMockCodeExposureWhenMockModeIsDisabled() {
        IllegalStateException exception = assertThrows(
                IllegalStateException.class,
                () -> validator(
                        "test",
                        STRONG_JWT_SECRET,
                        STRONG_PAYMENT_SECRET,
                        false,
                        verificationCode(false, "", true)
                ).afterPropertiesSet()
        );

        assertEquals("mock verification code exposure requires mock mode", exception.getMessage());
    }

    private ApplicationSafetyValidator validator(String runtimeMode,
                                                   String jwtSecret,
                                                   String paymentSecret,
                                                   boolean paymentMockEnabled,
                                                   VerificationCodeProperties verificationCode) {
        MockEnvironment environment = new MockEnvironment();
        if ("local".equals(runtimeMode) || "test".equals(runtimeMode)) {
            environment.setActiveProfiles(runtimeMode);
        }
        return new ApplicationSafetyValidator(
                environment,
                runtimeMode,
                jwtSecret,
                paymentSecret,
                paymentMockEnabled,
                verificationCode
        );
    }

    private VerificationCodeProperties verificationCode(boolean mockEnabled,
                                                          String mockCode,
                                                          boolean exposeMockCode) {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.setMockEnabled(mockEnabled);
        properties.setMockCode(mockCode);
        properties.setExposeMockCode(exposeMockCode);
        return properties;
    }
}
