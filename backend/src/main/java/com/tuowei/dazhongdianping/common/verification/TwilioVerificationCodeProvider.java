package com.tuowei.dazhongdianping.common.verification;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class TwilioVerificationCodeProvider implements VerificationCodeProvider {

    private final VerificationCodeProperties properties;
    private final RestClient restClient;

    public TwilioVerificationCodeProvider(
            VerificationCodeProperties properties,
            RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder.baseUrl(properties.getTwilio().getApiBaseUrl()).build();
    }

    @Override
    public String name() {
        return "TWILIO";
    }

    @Override
    public boolean isConfigured() {
        return properties.getTwilio().isConfigured() && !properties.isMockEnabled();
    }

    @Override
    public boolean supports(String target, int targetType) {
        if (targetType != 2 || !StringUtils.hasText(target)) {
            return false;
        }
        VerificationCodeProperties.Twilio twilio = properties.getTwilio();
        if (matchesPrefix(target, twilio.getExcludedRoutePrefixes())) {
            return false;
        }
        String prefixes = twilio.getRoutePrefixes();
        if (!StringUtils.hasText(prefixes) || "*".equals(prefixes.trim())) {
            return true;
        }
        return matchesPrefix(target, prefixes);
    }

    private boolean matchesPrefix(String target, String prefixes) {
        if (!StringUtils.hasText(prefixes)) {
            return false;
        }
        return java.util.Arrays.stream(prefixes.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .anyMatch(target::startsWith);
    }

    @Override
    public void send(String target, int targetType, String code, String scene) {
        if (!isConfigured() || !supports(target, targetType)) {
            throw new VerificationCodeSendException("Twilio 验证码通道未启用");
        }
        VerificationCodeProperties.Twilio twilio = properties.getTwilio();
        Map<String, String> form = new LinkedHashMap<>();
        form.put("To", target);
        if (StringUtils.hasText(twilio.getMessagingServiceSid())) {
            form.put("MessagingServiceSid", twilio.getMessagingServiceSid().trim());
        } else {
            form.put("From", twilio.getFrom().trim());
        }
        form.put("Body", "Your verification code is " + code + ". It expires in 5 minutes.");
        String authorization = Base64.getEncoder().encodeToString(
                (twilio.getAccountSid().trim() + ":" + twilio.getAuthToken().trim())
                        .getBytes(StandardCharsets.UTF_8)
        );
        try {
            restClient.post()
                    .uri("/2010-04-01/Accounts/{accountSid}/Messages.json", twilio.getAccountSid().trim())
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .header("Authorization", "Basic " + authorization)
                    .body(formBody(form))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException exception) {
            throw new VerificationCodeSendException("Twilio 验证码发送失败", exception);
        }
    }

    private String formBody(Map<String, String> form) {
        return form.entrySet().stream()
                .map(entry -> encode(entry.getKey()) + "=" + encode(entry.getValue()))
                .reduce((left, right) -> left + "&" + right)
                .orElse("");
    }

    private String encode(String value) {
        return java.net.URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
