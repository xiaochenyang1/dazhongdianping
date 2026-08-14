package com.tuowei.dazhongdianping.module.trade.service;

import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.model.TradeReconcileResult;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentChannelResolver;
import com.tuowei.dazhongdianping.module.trade.payment.RefundResult;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class TradeCompensationService {

    private static final Logger log = LoggerFactory.getLogger(TradeCompensationService.class);
    private static final int BATCH_SIZE = 100;

    private final TradeMapper mapper;
    private final PaymentChannelResolver channelResolver;
    private final TradeService tradeService;

    public TradeCompensationService(
            TradeMapper mapper,
            PaymentChannelResolver channelResolver,
            TradeService tradeService) {
        this.mapper = mapper;
        this.channelResolver = channelResolver;
        this.tradeService = tradeService;
    }

    public TradeReconcileResult reconcile() {
        int closedOrders = 0;
        int restoredStockOrders = 0;
        int failedPayments = 0;

        List<OrderRow> expiredOrders = mapper.selectExpiredUnpaidOrders(BATCH_SIZE);
        for (OrderRow order : expiredOrders) {
            if (mapper.closeExpiredUnpaidOrder(order.getId()) == 1) {
                closedOrders++;
                if (mapper.restoreDealStock(order.getDealId(), order.getQuantity()) == 1) {
                    restoredStockOrders++;
                }
            }
        }

        List<PaymentRow> stalePayments = mapper.selectStalePendingPayments(BATCH_SIZE);
        for (PaymentRow payment : stalePayments) {
            String raw = "auto_fail:order_expired_or_closed;orderNo=" + payment.getOrderNo()
                    + ";channelTxn=" + payment.getChannelTxn();
            if (mapper.markPaymentFailed(payment.getId(), raw) == 1) {
                failedPayments++;
            }
        }

        int reconciledRefunds = 0;
        List<RefundRow> processingRefunds = mapper.selectProcessingRefunds(BATCH_SIZE);
        for (RefundRow refund : processingRefunds) {
            try {
                PaymentChannel channel = channelResolver.resolveByChannel(refund.getChannel());
                RefundResult result = channel.queryRefund(refund.getChannelRefundTxn());
                if (result == null || result.state() == null || result.amount() == null
                        || refund.getAmount().compareTo(result.amount()) != 0) {
                    log.warn("refund reconcile returned invalid result: refundId={}", refund.getId());
                    continue;
                }
                Map<String, Object> applied = tradeService.applyRefundChannelState(
                        refund, result.state(), result.failureReason());
                if (Boolean.TRUE.equals(applied.get("processed"))) {
                    reconciledRefunds++;
                }
            } catch (RuntimeException exception) {
                log.warn(
                        "refund reconcile query failed: refundId={}, channel={}, refundTxn={}",
                        refund.getId(), refund.getChannel(), refund.getChannelRefundTxn(), exception
                );
            }
        }

        if (closedOrders > 0 || failedPayments > 0 || reconciledRefunds > 0) {
            log.info(
                    "trade reconcile finished: closedOrders={}, restoredStockOrders={}, failedPayments={}, reconciledRefunds={}",
                    closedOrders, restoredStockOrders, failedPayments, reconciledRefunds
            );
        }
        return new TradeReconcileResult(closedOrders, restoredStockOrders, failedPayments, reconciledRefunds);
    }
}
