package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import org.junit.jupiter.api.Test;

class TradeServiceFailClosedTest {

    private final TradeMapper mapper = mock(TradeMapper.class);
    private final TradeService service = new TradeService(
            mapper,
            mock(UserGrowthService.class),
            mock(CouponLifecycleService.class),
            mock(NotificationService.class),
            "payment-secret-for-runtime-safety-tests-001",
            false
    );

    @Test
    void shouldRejectPaymentIntentWhenMockPaymentIsDisabled() {
        assertThrows(ServiceUnavailableException.class, () -> service.pay(1L));
        verifyNoInteractions(mapper);
    }

    @Test
    void shouldRejectPaymentCallbackWhenMockPaymentIsDisabled() {
        assertThrows(ServiceUnavailableException.class, () -> service.notify("stripe_mock", null));
        verifyNoInteractions(mapper);
    }

    @Test
    void shouldRejectMockCompletionWhenMockPaymentIsDisabled() {
        assertThrows(ServiceUnavailableException.class, () -> service.completeMockPayment(1L));
        verifyNoInteractions(mapper);
    }
}
