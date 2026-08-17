package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import java.math.BigDecimal;
import java.util.Map;
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
        RegionContext.clear();
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

    @Test
    void shouldReturnExistingStripeClientSecretWhenPaymentIsRetried() {
        RegionContext.setRegion(Region.EU);
        OrderRow order = new OrderRow();
        order.setId(2L);
        order.setRegion("EU");
        order.setStatus(1);
        order.setPayStatus(0);
        order.setOrderNo("OD-EU-2");
        order.setAmount(new BigDecimal("12.50"));
        order.setCurrency("EUR");
        when(mapper.selectUserOrder(2L, 1L, "EU")).thenReturn(order);

        PaymentChannel channel = mock(PaymentChannel.class);
        reset(resolver);
        doReturn(channel).when(resolver).resolve("EU");
        PaymentRow payment = new PaymentRow();
        payment.setId(9L);
        payment.setChannel("stripe");
        payment.setChannelTxn("pi_existing");
        payment.setClientSecret("pi_existing_secret");
        payment.setAmount(order.getAmount());
        payment.setCurrency(order.getCurrency());
        when(mapper.selectPayment(2L)).thenReturn(payment);

        Map<String, Object> result = service.pay(2L);

        org.junit.jupiter.api.Assertions.assertEquals("pi_existing_secret", result.get("clientSecret"));
        org.junit.jupiter.api.Assertions.assertEquals("pi_existing", result.get("channelTxn"));
        org.mockito.Mockito.verify(channel, org.mockito.Mockito.never())
                .createIntent(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
        org.mockito.Mockito.verify(mapper, org.mockito.Mockito.never()).insertPayment(org.mockito.ArgumentMatchers.any());
    }

    private void verifyNoMoreInteractionsOnPaymentPaths() {
        org.mockito.Mockito.verify(mapper, org.mockito.Mockito.never())
            .selectPayment(org.mockito.ArgumentMatchers.anyLong());
        org.mockito.Mockito.verify(mapper, org.mockito.Mockito.never())
            .insertPayment(org.mockito.ArgumentMatchers.any());
    }
}
