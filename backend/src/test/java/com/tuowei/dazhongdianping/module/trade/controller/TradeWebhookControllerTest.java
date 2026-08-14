package com.tuowei.dazhongdianping.module.trade.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.trade.payment.ChannelWebhookResult;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.util.Map;
import org.junit.jupiter.api.Test;

class TradeWebhookControllerTest {

    private final TradeService service = mock(TradeService.class);
    private final PaymentChannelResolver resolver = mock(PaymentChannelResolver.class);
    private final TradeController controller = new TradeController(service, resolver);

    @Test
    void shouldProcessVerifiedStripeWebhook() {
        PaymentChannel channel = mock(PaymentChannel.class);
        ChannelWebhookResult verified = ChannelWebhookResult.paymentSucceeded(
                "OD12345", "pi_test_1", new BigDecimal("100.00"));
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhookEvent(request)).thenReturn(verified);
        when(service.handleChannelWebhook("stripe", verified))
            .thenReturn(Map.of("processed", true, "orderNo", "OD12345"));

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(true, response.data().get("processed"));
        verify(service).handleChannelWebhook("stripe", verified);
    }

    @Test
    void shouldDelegateIgnoredEventToTradeService() {
        PaymentChannel channel = mock(PaymentChannel.class);
        ChannelWebhookResult ignored = ChannelWebhookResult.ignored();
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhookEvent(request)).thenReturn(ignored);
        when(service.handleChannelWebhook("stripe", ignored))
                .thenReturn(Map.of("processed", false));

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(false, response.data().get("processed"));
        verify(service).handleChannelWebhook("stripe", ignored);
    }
}
