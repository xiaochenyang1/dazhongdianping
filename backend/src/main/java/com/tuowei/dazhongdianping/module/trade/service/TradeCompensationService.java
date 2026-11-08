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
    private final com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService marketingCouponService;
    private final com.tuowei.dazhongdianping.module.marketing.service.GroupBuyOrderService groupBuyOrderService;
    private final com.tuowei.dazhongdianping.module.marketing.service.GroupBuyMetrics groupBuyMetrics;

    public TradeCompensationService(
            TradeMapper mapper,
            PaymentChannelResolver channelResolver,
            TradeService tradeService,
            com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService marketingCouponService,
            com.tuowei.dazhongdianping.module.marketing.service.GroupBuyOrderService groupBuyOrderService,
            com.tuowei.dazhongdianping.module.marketing.service.GroupBuyMetrics groupBuyMetrics) {
        this.mapper = mapper;
        this.channelResolver = channelResolver;
        this.tradeService = tradeService;
        this.marketingCouponService = marketingCouponService;
        this.groupBuyOrderService = groupBuyOrderService;
        this.groupBuyMetrics = groupBuyMetrics;
    }

    public TradeReconcileResult reconcile() {
        int closedOrders = 0;
        int restoredStockOrders = 0;
        int failedPayments = 0;

        int expiredGroups = groupBuyOrderService.expireDueTeams(BATCH_SIZE);

        List<OrderRow> expiredOrders = mapper.selectExpiredUnpaidOrders(BATCH_SIZE);
        for (OrderRow order : expiredOrders) {
            try {
                if (tradeService.closeExpiredOrder(order.getId())) {
                    closedOrders++;
                    restoredStockOrders++;
                }
            } catch (RuntimeException failure) {
                log.warn("expired order close failed: orderId={}", order.getId(), failure);
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
        for (RefundRow refund : mapper.selectUnsubmittedAutoRefunds(BATCH_SIZE)) {
            try {
                boolean processed = tradeService.processAutomaticRefund(refund.getOrderId());
                if (processed) reconciledRefunds++;
                recordGroupBuyRefund(refund, processed);
            } catch (RuntimeException failure) {
                recordGroupBuyFailure(refund, "refund_submission");
                log.warn("automatic refund submission failed: refundId={}", refund.getId(), failure);
            }
        }
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
                recordGroupBuyFailure(refund, "refund_query");
                log.warn(
                        "refund reconcile query failed: refundId={}, channel={}, refundTxn={}",
                        refund.getId(), refund.getChannel(), refund.getChannelRefundTxn(), exception
                );
            }
        }

        if (closedOrders > 0 || failedPayments > 0 || reconciledRefunds > 0 || expiredGroups > 0) {
            log.info(
                    "trade reconcile finished: expiredGroups={}, closedOrders={}, restoredStockOrders={}, failedPayments={}, reconciledRefunds={}",
                    expiredGroups, closedOrders, restoredStockOrders, failedPayments, reconciledRefunds
            );
        }
        return new TradeReconcileResult(closedOrders, restoredStockOrders, failedPayments, reconciledRefunds);
    }

    private void recordGroupBuyRefund(RefundRow refund, boolean submitted) {
        if (!"groupbuy_expired".equals(refund.getRefundType())) return;
        OrderRow order = mapper.selectOrderById(refund.getOrderId());
        groupBuyMetrics.automaticRefund(order == null ? "unknown" : order.getRegion(), submitted);
    }

    private void recordGroupBuyFailure(RefundRow refund, String stage) {
        if (!"groupbuy_expired".equals(refund.getRefundType())) return;
        OrderRow order = mapper.selectOrderById(refund.getOrderId());
        groupBuyMetrics.failure(order == null ? "unknown" : order.getRegion(), stage);
    }
}
