package com.tuowei.dazhongdianping.module.trade.service;

import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.TradeReconcileResult;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TradeCompensationService {

    private static final Logger log = LoggerFactory.getLogger(TradeCompensationService.class);
    private static final int BATCH_SIZE = 100;

    private final TradeMapper mapper;

    public TradeCompensationService(TradeMapper mapper) {
        this.mapper = mapper;
    }

    @Transactional
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

        if (closedOrders > 0 || failedPayments > 0) {
            log.info(
                    "trade reconcile finished: closedOrders={}, restoredStockOrders={}, failedPayments={}",
                    closedOrders,
                    restoredStockOrders,
                    failedPayments
            );
        }
        return new TradeReconcileResult(closedOrders, restoredStockOrders, failedPayments);
    }
}
