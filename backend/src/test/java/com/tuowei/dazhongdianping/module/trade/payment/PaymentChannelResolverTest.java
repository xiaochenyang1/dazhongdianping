package com.tuowei.dazhongdianping.module.trade.payment;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class PaymentChannelResolverTest {

    private final MockPaymentChannel mockChannel = mock(MockPaymentChannel.class);
    private final StripePaymentChannel stripeChannel = mock(StripePaymentChannel.class);

    private PaymentChannelResolver resolver(boolean stripeEnabled, boolean mockEnabled,
                                            boolean stripeBeanPresent) {
        return new PaymentChannelResolver(
            mockChannel,
            stripeBeanPresent ? Optional.of(stripeChannel) : Optional.empty(),
            stripeEnabled,
            mockEnabled);
    }

    @Test
    void shouldRouteEuToStripeWhenEnabled() {
        assertSame(stripeChannel, resolver(true, true, true).resolve("EU"));
    }

    @Test
    void shouldRouteEuToMockWhenStripeDisabled() {
        assertSame(mockChannel, resolver(false, true, false).resolve("EU"));
    }

    @Test
    void shouldAlwaysRouteCnToMock() {
        assertSame(mockChannel, resolver(true, true, true).resolve("CN"));
    }

    @Test
    void shouldFailClosedWhenBothDisabled() {
        assertThrows(ServiceUnavailableException.class,
            () -> resolver(false, false, false).resolve("EU"));
    }

    @Test
    void shouldFailClosedWhenStripeEnabledButBeanMissing() {
        assertThrows(ServiceUnavailableException.class,
            () -> resolver(true, false, false).resolve("EU"));
    }

    @Test
    void shouldResolveByChannelName() {
        PaymentChannelResolver r = resolver(true, true, true);
        assertSame(stripeChannel, r.resolveByChannel("stripe"));
        assertSame(mockChannel, r.resolveByChannel("alipay_mock"));
        assertSame(mockChannel, r.resolveByChannel("stripe_mock"));
    }
}
