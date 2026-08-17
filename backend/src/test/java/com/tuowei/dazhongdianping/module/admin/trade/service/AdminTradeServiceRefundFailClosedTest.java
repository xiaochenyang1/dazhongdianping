package com.tuowei.dazhongdianping.module.admin.trade.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.trade.mapper.AdminTradeMapper;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.request.AdminRefundAuditRequest;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.RefundResult;
import com.tuowei.dazhongdianping.module.trade.service.TradeCompensationService;
import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Fail-closed contract for the admin refund audit: when the channel refund
 * cannot be issued (resolver unavailable, channel throws, or channel returns an
 * incomplete receipt) the approval MUST propagate {@link ServiceUnavailableException}
 * so the surrounding {@code @Transactional} rolls back, never leaving the DB in an
 * approved-but-not-refunded state. Mirrors {@code TradeServiceFailClosedTest}.
 */
class AdminTradeServiceRefundFailClosedTest {

    private final AdminTradeMapper mapper = mock(AdminTradeMapper.class);
    private final AdminAuditMapper adminAuditMapper = mock(AdminAuditMapper.class);
    private final TradeMapper tradeMapper = mock(TradeMapper.class);
    private final PaymentChannelResolver channelResolver = mock(PaymentChannelResolver.class);

    private final AdminTradeService service = new AdminTradeService(
            mapper,
            adminAuditMapper,
            mock(TradeCompensationService.class),
            mock(NotificationService.class),
            tradeMapper,
            channelResolver
    );

    private static final Long ORDER_ID = 9302L;
    private static final Long ADMIN_ID = 1L;

    @BeforeEach
    void setUpSession() {
        AdminSessionContext.set(new AdminSession(
                ADMIN_ID, "admin", "管理员", Set.of(), Set.of("CN"),
                Map.of("CN", new AdminCityScope(true, Set.of(), Set.of()))
        ));
        RegionContext.setRegion(Region.CN);

        AdminOrderRow order = new AdminOrderRow();
        order.setId(ORDER_ID);
        order.setDealId(40001L);
        order.setQuantity(1);
        order.setUserId(9002L);
        order.setShopId(10001L);
        order.setOrderNo("ADMIN-ORDER-002");
        order.setDealTitle("测试团购");
        when(mapper.selectOrderById(anyString(), anyLong(), anyBoolean(), any(), any()))
                .thenReturn(order);

        RefundRow refund = new RefundRow();
        refund.setId(9502L);
        refund.setOrderId(ORDER_ID);
        refund.setStatus(0);
        refund.setAmount(new BigDecimal("88.00"));
        when(mapper.selectRefundByOrder(ORDER_ID)).thenReturn(refund);

        when(mapper.approveRefund(anyLong(), anyLong(), anyString())).thenReturn(1);
        when(mapper.markOrderRefunded(anyLong())).thenReturn(1);
        when(mapper.restoreDealStock(anyLong(), anyInt())).thenReturn(1);

        PaymentRow payment = new PaymentRow();
        payment.setChannel("alipay_mock");
        payment.setChannelTxn("TX-ADMIN-002");
        when(tradeMapper.selectPayment(ORDER_ID)).thenReturn(payment);
        when(tradeMapper.recordRefundChannelResult(anyLong(), anyString(), anyString(), anyString(), anyString()))
                .thenReturn(1);
    }

    @AfterEach
    void clearSession() {
        AdminSessionContext.clear();
        RegionContext.clear();
    }

    @Test
    void shouldFailClosedWhenChannelResolverUnavailable() {
        when(channelResolver.resolveByChannel(anyString()))
                .thenThrow(new ServiceUnavailableException("支付渠道暂时不可用"));

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new AdminRefundAuditRequest("approve", "用户投诉属实"), "127.0.0.1"));

        // Channel resolution happens before any local refund/order/stock transition.
        verify(channelResolver).resolveByChannel("alipay_mock");
        verify(mapper, never()).approveRefund(anyLong(), anyLong(), anyString());
        verify(mapper, never()).restoreDealStock(anyLong(), anyInt());
        verify(adminAuditMapper, never()).insertAuditLog(
                anyLong(), anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void shouldFailClosedWhenChannelRefundReturnsIncompleteReceipt() {
        PaymentChannel channel = mock(PaymentChannel.class);
        when(channel.refund(any(), any(), anyString(), anyString())).thenReturn(
                new RefundResult("alipay_mock", "", new BigDecimal("88.00"), false));
        when(channelResolver.resolveByChannel(anyString())).thenReturn(channel);

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new AdminRefundAuditRequest("approve", "用户投诉属实"), "127.0.0.1"));

        verify(adminAuditMapper, never()).insertAuditLog(
                anyLong(), anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void shouldFailClosedWhenPaymentRecordMissing() {
        when(tradeMapper.selectPayment(ORDER_ID)).thenReturn(null);

        assertThrows(ServiceUnavailableException.class, () ->
                service.auditRefund(ORDER_ID,
                        new AdminRefundAuditRequest("approve", "用户投诉属实"), "127.0.0.1"));

        // never even reached the resolver
        verify(channelResolver, never()).resolveByChannel(anyString());
    }
}
