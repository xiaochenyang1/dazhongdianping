package com.tuowei.dazhongdianping.module.trade.payment;

import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import jakarta.servlet.http.HttpServletRequest;

public interface PaymentChannel {
    PaymentIntentResult createIntent(OrderRow order, PaymentRow payment);
    PaymentNotifyResult verifyWebhook(HttpServletRequest rawRequest);
    boolean supports(String region, String channel);
}
