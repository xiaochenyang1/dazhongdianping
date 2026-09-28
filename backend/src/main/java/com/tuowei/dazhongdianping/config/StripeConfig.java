package com.tuowei.dazhongdianping.config;

import com.stripe.StripeClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StripeConfig {

    /**
     * Explicit connect/read timeouts and a bounded retry count are set so a slow
     * or hanging Stripe endpoint cannot pin a pooled DB connection for the SDK's
     * default (~80s) read window — the refund flows deliberately call Stripe
     * inside their fail-closed transaction, so the call duration must stay
     * bounded. Idempotency keys are already attached per request, so a network
     * retry is safe (Stripe de-duplicates).
     */
    @Bean
    @ConditionalOnProperty(name = "app.payment.stripe.enabled", havingValue = "true")
    public StripeClient stripeClient(
            @Value("${app.payment.stripe.secret-key}") String secretKey,
            @Value("${app.payment.stripe.connect-timeout-ms:5000}") int connectTimeoutMs,
            @Value("${app.payment.stripe.read-timeout-ms:20000}") int readTimeoutMs,
            @Value("${app.payment.stripe.max-network-retries:1}") int maxNetworkRetries) {
        if (secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException(
                "app.payment.stripe.enabled=true 但未配置 app.payment.stripe.secret-key");
        }
        return StripeClient.builder()
                .setApiKey(secretKey)
                .setConnectTimeout(connectTimeoutMs)
                .setReadTimeout(readTimeoutMs)
                .setMaxNetworkRetries(maxNetworkRetries)
                .build();
    }
}
