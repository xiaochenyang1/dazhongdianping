package com.tuowei.dazhongdianping.common.verification;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import java.util.Locale;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class SmtpVerificationCodeProvider implements VerificationCodeProvider {

    private final VerificationCodeProperties properties;
    private final JavaMailSender mailSender;

    public SmtpVerificationCodeProvider(
            VerificationCodeProperties properties,
            ObjectProvider<JavaMailSender> mailSenderProvider) {
        this.properties = properties;
        this.mailSender = mailSenderProvider.getIfAvailable();
    }

    @Override
    public String name() {
        return "SMTP";
    }

    @Override
    public boolean isConfigured() {
        return properties.getMail().isConfigured() && mailSender != null && !properties.isMockEnabled();
    }

    @Override
    public boolean supports(String target, int targetType) {
        return targetType == 1;
    }

    @Override
    public void send(String target, int targetType, String code, String scene) {
        if (!isConfigured() || !supports(target, targetType)) {
            throw new VerificationCodeSendException("SMTP 验证码通道未启用");
        }
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(properties.getMail().getFrom().trim());
        message.setTo(target);
        message.setSubject(properties.getMail().getSubject().trim());
        message.setText(emailBody(code, scene));
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            throw new VerificationCodeSendException("SMTP 验证码发送失败", exception);
        }
    }

    private String emailBody(String code, String scene) {
        return properties.getMail().getBrandName().trim() + "\n\nYour verification code is " + code
                + ". It expires in 5 minutes. Scene: "
                + scene.toLowerCase(Locale.ROOT)
                + ". If you did not request this code, ignore this email.";
    }
}
