package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TradeServiceFailClosedTest {

    private final TradeMapper mapper = mock(TradeMapper.class);
    private final PaymentChannelResolver resolver = mock(PaymentChannelResolver.class);
    private final TradeService service = new TradeService(
            mapper,
            mock(UserGrowthService.class),
            mock(CouponLifecycleService.class),
            mock(NotificationService.class),
            "payment-secret-for-runtime-safety-tests-001",
            resolver
    );

    @BeforeEach
    void setUpSession() {
        UserSessionContext.set(new UserSession(1L, 1L));
        OrderRow order = new OrderRow();
        order.setId(1L);
        order.setRegion("CN");
        when(mapper.selectUserOrder(org.mockito.ArgumentMatchers.anyLong(),
                org.mockito.ArgumentMatchers.anyLong(),
                org.mockito.ArgumentMatchers.anyString())).thenReturn(order);
        when(resolver.resolve(org.mockito.ArgumentMatchers.anyString()))
            .thenThrow(new ServiceUnavailableException("支付渠道尚未配置"));
    }

    @AfterEach
    void clearSession() {
        UserSessionContext.clear();
    }

    @Test
    void shouldRejectPaymentIntentWhenNoChannelConfigured() {
        assertThrows(ServiceUnavailableException.class, () -> service.pay(1L));
        verifyNoMoreInteractionsOnPaymentPaths();
    }

    @Test
    void shouldRejectMockCompletionWhenNoChannelConfigured() {
        assertThrows(ServiceUnavailableException.class, () -> service.completeMockPayment(1L));
        verifyNoMoreInteractionsOnPaymentPaths();
    }

    private void verifyNoMoreInteractionsOnPaymentPaths() {
        org.mockito.Mockito.verify(mapper, org.mockito.Mockito.never())
            .selectPayment(org.mockito.ArgumentMatchers.anyLong());
        org.mockito.Mockito.verify(mapper, org.mockito.Mockito.never())
            .insertPayment(org.mockito.ArgumentMatchers.any());
    }
}
