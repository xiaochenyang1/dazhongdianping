package com.tuowei.dazhongdianping.module.trade.payment;

import com.stripe.StripeClient;
import com.stripe.exception.ApiConnectionException;
import com.stripe.exception.AuthenticationException;
import com.stripe.exception.InvalidRequestException;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnBean(StripeClient.class)
public class StripePaymentChannel implements PaymentChannel {

    public static final String CHANNEL = "stripe";

    private final StripeClient stripeClient;
    private final String endpointSecret;

    public StripePaymentChannel(
            StripeClient stripeClient,
            @Value("${app.payment.stripe.endpoint-secret:}") String endpointSecret) {
        this.stripeClient = stripeClient;
        this.endpointSecret = endpointSecret;
    }

    @Override
    public PaymentIntentResult createIntent(OrderRow order, PaymentRow payment) {
        PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                .setAmount(toMinorUnits(order.getAmount()))
                .setCurrency(order.getCurrency().toLowerCase())
                .putMetadata("orderNo", order.getOrderNo())
                .addPaymentMethodType("card")
                .setCaptureMethod(PaymentIntentCreateParams.CaptureMethod.AUTOMATIC)
                .build();
        try {
            PaymentIntent intent = stripeClient.paymentIntents().create(params);
            return new PaymentIntentResult(CHANNEL, intent.getId(), intent.getClientSecret());
        } catch (StripeException e) {
            throw translate(e);
        }
    }

    @Override
    public PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest) {
        throw new UnsupportedOperationException("verifyWebhook implemented in Task 5");
    }

    @Override
    public boolean supports(String region, String channel) {
        return CHANNEL.equals(channel);
    }

    private long toMinorUnits(BigDecimal amount) {
        return amount.movePointRight(2).longValueExact();
    }

    private RuntimeException translate(StripeException e) {
        if (e instanceof InvalidRequestException) {
            return new IllegalArgumentException(e.getMessage());
        }
        if (e instanceof AuthenticationException || e instanceof ApiConnectionException) {
            return new ServiceUnavailableException("支付渠道暂时不可用");
        }
        return new ServiceUnavailableException("支付渠道暂时不可用");
    }
}
