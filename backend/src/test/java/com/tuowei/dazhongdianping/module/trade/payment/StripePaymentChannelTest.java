package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.stripe.StripeClient;
import com.stripe.exception.AuthenticationException;
import com.stripe.model.PaymentIntent;
import com.stripe.service.PaymentIntentService;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class StripePaymentChannelTest {

    private final StripeClient stripeClient = mock(StripeClient.class);
    private final PaymentIntentService intentService = mock(PaymentIntentService.class);
    private final StripePaymentChannel channel =
        new StripePaymentChannel(stripeClient, "whsec_test_secret");

    private OrderRow order() {
        OrderRow o = new OrderRow();
        o.setRegion("EU");
        o.setOrderNo("OD12345");
        o.setAmount(new BigDecimal("100.00"));
        o.setCurrency("EUR");
        return o;
    }

    @Test
    void shouldCreateIntentAndReturnClientSecret() throws Exception {
        PaymentIntent stripeIntent = mock(PaymentIntent.class);
        when(stripeIntent.getId()).thenReturn("pi_test_123");
        when(stripeIntent.getClientSecret()).thenReturn("pi_test_123_secret_abc");
        when(stripeClient.paymentIntents()).thenReturn(intentService);
        when(intentService.create(any(com.stripe.param.PaymentIntentCreateParams.class)))
            .thenReturn(stripeIntent);

        PaymentIntentResult result = channel.createIntent(order(), new PaymentRow());

        assertEquals("stripe", result.channel());
        assertEquals("pi_test_123", result.channelTxn());
        assertEquals("pi_test_123_secret_abc", result.clientSecret());
    }

    @Test
    void shouldMapAuthenticationExceptionToServiceUnavailable() throws Exception {
        when(stripeClient.paymentIntents()).thenReturn(intentService);
        when(intentService.create(any(com.stripe.param.PaymentIntentCreateParams.class)))
            .thenThrow(new AuthenticationException("bad key", null, null, 401));

        assertThrows(ServiceUnavailableException.class,
            () -> channel.createIntent(order(), new PaymentRow()));
    }

    @Test
    void shouldSupportOnlyStripeChannel() {
        assertTrue(channel.supports("EU", "stripe"));
        assertFalse(channel.supports("EU", "stripe_mock"));
        assertFalse(channel.supports("CN", "alipay_mock"));
    }
}
