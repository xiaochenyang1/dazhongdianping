package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.model.TradeReconcileResult;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.RefundChannelState;
import com.tuowei.dazhongdianping.module.trade.payment.RefundResult;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class TradeCompensationServiceTest {

    @Test
    void reportsRefundsWhoseChannelStateWasApplied() {
        TradeMapper mapper = mock(TradeMapper.class);
        PaymentChannelResolver resolver = mock(PaymentChannelResolver.class);
        TradeService tradeService = mock(TradeService.class);
        PaymentChannel channel = mock(PaymentChannel.class);
        TradeCompensationService service = new TradeCompensationService(mapper, resolver, tradeService);

        RefundRow refund = new RefundRow();
        refund.setId(91L);
        refund.setChannel("stripe");
        refund.setChannelRefundTxn("re_91");
        refund.setAmount(new BigDecimal("12.50"));

        when(mapper.selectExpiredUnpaidOrders(100)).thenReturn(List.of());
        when(mapper.selectStalePendingPayments(100)).thenReturn(List.of());
        when(mapper.selectProcessingRefunds(100)).thenReturn(List.of(refund));
        when(resolver.resolveByChannel("stripe")).thenReturn(channel);
        when(channel.queryRefund("re_91")).thenReturn(new RefundResult(
                "stripe", "re_91", new BigDecimal("12.50"), RefundChannelState.SUCCEEDED, ""));
        when(tradeService.applyRefundChannelState(refund, RefundChannelState.SUCCEEDED, ""))
                .thenReturn(Map.of("processed", true));

        TradeReconcileResult result = service.reconcile();

        assertEquals(0, result.closedOrders());
        assertEquals(0, result.restoredStockOrders());
        assertEquals(0, result.failedPayments());
        assertEquals(1, result.reconciledRefunds());
        verify(tradeService).applyRefundChannelState(refund, RefundChannelState.SUCCEEDED, "");
    }
}
