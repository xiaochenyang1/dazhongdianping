package com.tuowei.dazhongdianping.common.verification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

class SmtpVerificationCodeProviderTest {

    @Test
    void shouldRequireCompleteConfigurationSenderAndDisabledMockMode() {
        VerificationCodeProperties properties = configuredProperties();
        JavaMailSender mailSender = mock(JavaMailSender.class);

        assertThat(provider(properties, mailSender).isConfigured()).isTrue();
        assertThat(provider(properties, null).isConfigured()).isFalse();

        properties.setMockEnabled(true);
        assertThat(provider(properties, mailSender).isConfigured()).isFalse();

        properties.setMockEnabled(false);
        properties.getMail().setHost("  ");
        assertThat(provider(properties, mailSender).isConfigured()).isFalse();
    }

    @Test
    void shouldRouteOnlyEmailTargets() {
        SmtpVerificationCodeProvider provider = provider(configuredProperties(), mock(JavaMailSender.class));

        assertThat(provider.name()).isEqualTo("SMTP");
        assertThat(provider.supports("alice@example.com", 1)).isTrue();
        assertThat(provider.supports("+14155550123", 2)).isFalse();
    }

    @Test
    void shouldConstructAndSendExpectedMail() {
        VerificationCodeProperties properties = configuredProperties();
        JavaMailSender mailSender = mock(JavaMailSender.class);
        SmtpVerificationCodeProvider provider = provider(properties, mailSender);

        provider.send("alice@example.com", 1, "654321", "REGISTER");

        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender).send(captor.capture());
        SimpleMailMessage message = captor.getValue();
        assertThat(message.getFrom()).isEqualTo("no-reply@example.com");
        assertThat(message.getTo()).containsExactly("alice@example.com");
        assertThat(message.getSubject()).isEqualTo("Your verification code");
        assertThat(message.getText()).isEqualTo(
                "Dianping EU\n\nYour verification code is 654321. "
                        + "It expires in 5 minutes. Scene: register. "
                        + "If you did not request this code, ignore this email."
        );
    }

    @Test
    void shouldRejectDisabledOrUnsupportedChannelBeforeSending() {
        VerificationCodeProperties properties = configuredProperties();
        JavaMailSender mailSender = mock(JavaMailSender.class);
        SmtpVerificationCodeProvider provider = provider(properties, mailSender);

        assertThatThrownBy(() -> provider.send("+14155550123", 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("SMTP 验证码通道未启用");

        properties.getMail().setEnabled(false);
        assertThatThrownBy(() -> provider.send("alice@example.com", 1, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("SMTP 验证码通道未启用");
    }

    @Test
    void shouldWrapMailFailureWithoutPuttingProviderDetailInPublicMessage() {
        VerificationCodeProperties properties = configuredProperties();
        JavaMailSender mailSender = mock(JavaMailSender.class);
        doThrow(new MailAuthenticationException("smtp-provider-sensitive-detail"))
                .when(mailSender).send(any(SimpleMailMessage.class));
        SmtpVerificationCodeProvider provider = provider(properties, mailSender);

        assertThatThrownBy(() -> provider.send("alice@example.com", 1, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("SMTP 验证码发送失败")
                .hasMessageNotContaining("smtp-provider-sensitive-detail")
                .hasCauseInstanceOf(MailAuthenticationException.class);
    }

    private VerificationCodeProperties configuredProperties() {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.getMail().setEnabled(true);
        properties.getMail().setHost("smtp.example.com");
        properties.getMail().setFrom(" no-reply@example.com ");
        properties.getMail().setSubject(" Your verification code ");
        properties.getMail().setBrandName(" Dianping EU ");
        return properties;
    }

    @SuppressWarnings("unchecked")
    private SmtpVerificationCodeProvider provider(
            VerificationCodeProperties properties,
            JavaMailSender mailSender) {
        ObjectProvider<JavaMailSender> mailSenderProvider = mock(ObjectProvider.class);
        when(mailSenderProvider.getIfAvailable()).thenReturn(mailSender);
        return new SmtpVerificationCodeProvider(properties, mailSenderProvider);
    }
}
