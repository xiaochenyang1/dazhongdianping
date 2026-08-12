package com.tuowei.dazhongdianping.common.verification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNoException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import org.junit.jupiter.api.Test;

/**
 * 纯单测,直接 new 实例化,覆盖 {@link ConsoleVerificationCodeProvider} 的激活与发送契约。
 */
class ConsoleVerificationCodeProviderTest {

    private static final String TARGET = "alice@example.com";

    @Test
    void shouldNotBeConfiguredWhenFlagIsOff() {
        ConsoleVerificationCodeProvider provider = newProvider(false, false);

        assertThat(provider.isConfigured()).isFalse();
    }

    @Test
    void shouldNotBeConfiguredWhenMockIsOnEvenIfFlagIsOn() {
        // mock 开时控制台让位给 mock 路径
        ConsoleVerificationCodeProvider provider = newProvider(true, true);

        assertThat(provider.isConfigured()).isFalse();
    }

    @Test
    void shouldBeConfiguredWhenFlagIsOnAndMockIsOff() {
        ConsoleVerificationCodeProvider provider = newProvider(true, false);

        assertThat(provider.isConfigured()).isTrue();
        assertThat(provider.name()).isEqualTo("CONSOLE");
    }

    @Test
    void shouldNotThrowWhenSendingAndConfigured() {
        ConsoleVerificationCodeProvider provider = newProvider(true, false);

        assertThatNoException()
                .isThrownBy(() -> provider.send(TARGET, 1, "654321", "login"));
    }

    @Test
    void shouldThrowWhenSendingAndNotConfigured() {
        ConsoleVerificationCodeProvider provider = newProvider(false, false);

        assertThatThrownBy(() -> provider.send(TARGET, 1, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessageContaining("控制台验证码通道未启用");
    }

    @Test
    void shouldMaskTargetLeavingFirstAndLastTwoChars() {
        assertThat(ConsoleVerificationCodeProvider.mask("alice@example.com"))
                .isEqualTo("al***om");
        assertThat(ConsoleVerificationCodeProvider.mask("ab")).isEqualTo("***");
        assertThat(ConsoleVerificationCodeProvider.mask("abcd")).isEqualTo("***");
        assertThat(ConsoleVerificationCodeProvider.mask("")).isEqualTo("");
        assertThat(ConsoleVerificationCodeProvider.mask(null)).isEqualTo("");
    }

    private ConsoleVerificationCodeProvider newProvider(boolean devConsoleEnabled, boolean mockEnabled) {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.setDevConsoleEnabled(devConsoleEnabled);
        properties.setMockEnabled(mockEnabled);
        return new ConsoleVerificationCodeProvider(properties);
    }
}
