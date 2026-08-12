package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;

public interface PaymentChannel {
    PaymentIntentResult createIntent(OrderRow order, PaymentRow payment);
    PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest);
    boolean supports(String region, String channel);

    /**
     * Issue a refund for {@code amount} against the original {@code payment}.
     * <p>Implementations MUST fail-closed: any channel error propagates so the
     * caller's {@code @Transactional} audit approval rolls back, never leaving
     * the DB in an approved-but-not-refunded state.
     *
     * @param payment the original captured payment (carries {@code channel} + {@code channelTxn})
     * @param amount  refund amount in major units (same currency/scale as the payment)
     * @param reason  human-readable refund reason, may be blank
     * @return channel refund receipt (channel, channel refund txn id, amount, success)
     */
    RefundResult refund(PaymentRow payment, BigDecimal amount, String reason);
}
