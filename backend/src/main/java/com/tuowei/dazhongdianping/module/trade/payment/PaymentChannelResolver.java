package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PaymentChannelResolver {

    private final MockPaymentChannel mockChannel;
    private final Optional<StripePaymentChannel> stripeChannel;
    private final boolean stripeEnabled;
    private final boolean mockEnabled;

    public PaymentChannelResolver(
            MockPaymentChannel mockChannel,
            Optional<StripePaymentChannel> stripeChannel,
            @Value("${app.payment.stripe.enabled:false}") boolean stripeEnabled,
            @Value("${app.payment.mock-enabled:false}") boolean mockEnabled) {
        this.mockChannel = mockChannel;
        this.stripeChannel = stripeChannel;
        this.stripeEnabled = stripeEnabled;
        this.mockEnabled = mockEnabled;
    }

    public PaymentChannel resolve(String region) {
        if (!"CN".equals(region) && stripeEnabled && stripeChannel.isPresent()) {
            return stripeChannel.get();
        }
        if (mockEnabled) {
            return mockChannel;
        }
        throw new ServiceUnavailableException("支付渠道尚未配置");
    }

    public PaymentChannel resolveByChannel(String channel) {
        if (StripePaymentChannel.CHANNEL.equals(channel)) {
            if (stripeEnabled && stripeChannel.isPresent()) {
                return stripeChannel.get();
            }
            throw new ServiceUnavailableException("支付渠道尚未配置");
        }
        if (mockEnabled) {
            return mockChannel;
        }
        throw new ServiceUnavailableException("支付渠道尚未配置");
    }
}
