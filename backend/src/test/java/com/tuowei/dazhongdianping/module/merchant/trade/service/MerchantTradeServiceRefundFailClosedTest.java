package com.tuowei.dazhongdianping.module.merchant.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.trade.mapper.MerchantTradeMapper;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantRefundAuditRequest;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.RefundResult;
import java.math.BigDecimal;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Fail-closed contract for the merchant refund audit: when the channel refund
 * cannot be issued (resolver unavailable, channel throws, or channel returns a
 * non-success receipt) the approval MUST propagate {@link ServiceUnavailableException}
 * so the surrounding {@code @Transactional} rolls back, never leaving the DB in an
 * approved-but-not-refunded state. Mirrors {@code TradeServiceFailClosedTest}.
 */
class MerchantTradeServiceRefundFailClosedTest {

    private final MerchantTradeMapper mapper = mock(MerchantTradeMapper.class);
    private final TradeMapper tradeMapper = mock(TradeMapper.class);
    private final PaymentChannelResolver channelResolver = mock(PaymentChannelResolver.class);
    private final MerchantAuthorizationService authorizationService = mock(MerchantAuthorizationService.class);

    private final MerchantTradeService service = new MerchantTradeService(
            mapper,
            mock(AdminAuditMapper.class),
            authorizationService,
            mock(NotificationService.class),
            tradeMapper,
            channelResolver
    );

    private static final Long ORDER_ID = 7701L;

    @BeforeEach
    void setUpSession() {
        MerchantSessionContext.set(new MerchantSession(
                12001L, 1001L, "merchant", 1, "CN"));
        RegionContext.setRegion(Region.CN);

        OrderRow order = new OrderRow();
        order.setId(ORDER_ID);
        order.setDealId(40001L);
        order.setQuantity(1);
        order.setShopId(10001L);
        order.setUserId(8001L);
        order.setOrderNo("MERCHANT-ORDER-001");
        order.setDealTitle("测试团购");
        when(mapper.selectOrder(anyLong(), anyLong(), anyString())).thenReturn(order);

        RefundRow refund = new RefundRow();
        refund.setStatus(0);
        refund.setAmount(new BigDecimal("88.00"));
        when(mapper.selectRefund(ORDER_ID)).thenReturn(refund);

        when(mapper.approveRefund(anyLong(), anyLong(), anyString())).thenReturn(1);
        when(mapper.markOrderRefunded(anyLong())).thenReturn(1);
        when(mapper.restoreDealStock(anyLong(), anyInt())).thenReturn(1);

        PaymentRow payment = new PaymentRow();
        payment.setChannel("alipay_mock");
        payment.setChannelTxn("TX-MERCHANT-001");
        when(tradeMapper.selectPayment(ORDER_ID)).thenReturn(payment);
    }

    @AfterEach
    void clearSession() {
        MerchantSessionContext.clear();
        RegionContext.clear();
    }

    @Test
    void shouldFailClosedWhenChannelResolverUnavailable() {
        when(channelResolver.resolveByChannel(anyString()))
                .thenThrow(new ServiceUnavailableException("支付渠道暂时不可用"));

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new MerchantRefundAuditRequest("approve", "用户申请退款")));

        // approval reached the channel-refund step (stock restored) but never
        // wrote the operation log → surrounding @Transactional rolls back the approve.
        verify(mapper).restoreDealStock(anyLong(), anyInt());
        verify(mapper, never()).insertOperationLog(
                anyLong(), anyLong(), anyString(), anyString(), anyLong(), anyString());
    }

    @Test
    void shouldFailClosedWhenChannelRefundReturnsNonSuccess() {
        PaymentChannel channel = mock(PaymentChannel.class);
        when(channel.refund(any(), any(), anyString())).thenReturn(
                new RefundResult("alipay_mock", "RF1", new BigDecimal("88.00"), false));
        when(channelResolver.resolveByChannel(anyString())).thenReturn(channel);

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new MerchantRefundAuditRequest("approve", "用户申请退款")));

        verify(mapper, never()).insertOperationLog(
                anyLong(), anyLong(), anyString(), anyString(), anyLong(), anyString());
    }

    @Test
    void shouldFailClosedWhenPaymentRecordMissing() {
        when(tradeMapper.selectPayment(ORDER_ID)).thenReturn(null);

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new MerchantRefundAuditRequest("approve", "用户申请退款")));

        // never even reached the resolver
        verify(channelResolver, never()).resolveByChannel(anyString());
    }
}
