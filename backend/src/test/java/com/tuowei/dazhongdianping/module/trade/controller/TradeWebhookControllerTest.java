package com.tuowei.dazhongdianping.module.trade.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentNotifyResult;
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
        PaymentNotifyResult verified =
            new PaymentNotifyResult("OD12345", "pi_test_1", new BigDecimal("100.00"), true);
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhook(request)).thenReturn(verified);
        when(service.notifyInternal(eq("stripe"), any(PaymentNotifyResult.class)))
            .thenReturn(Map.of("processed", true, "orderNo", "OD12345"));

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(true, response.data().get("processed"));
        verify(service).notifyInternal(eq("stripe"), any(PaymentNotifyResult.class));
    }

    @Test
    void shouldAcknowledgeIgnoredEventWithoutTouchingTradeService() {
        PaymentChannel channel = mock(PaymentChannel.class);
        PaymentNotifyResult ignored = new PaymentNotifyResult(null, null, null, false);
        HttpServletRequest request = mock(HttpServletRequest.class);

        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.verifyWebhook(request)).thenReturn(ignored);

        ApiResponse<Map<String, Object>> response = controller.notifyStripe(request);

        assertEquals(false, response.data().get("processed"));
        verifyNoInteractions(service);
    }
}
