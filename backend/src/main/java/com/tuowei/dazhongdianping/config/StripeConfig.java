package com.tuowei.dazhongdianping.config;

import com.stripe.StripeClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StripeConfig {

    @Bean
    @ConditionalOnProperty(name = "app.payment.stripe.enabled", havingValue = "true")
    public StripeClient stripeClient(
            @Value("${app.payment.stripe.secret-key}") String secretKey) {
        if (secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException(
                "app.payment.stripe.enabled=true 但未配置 app.payment.stripe.secret-key");
        }
        return new StripeClient(secretKey);
    }
}
