package com.tuowei.dazhongdianping.module.admin.groupbuy.model.response;

public record AdminGroupBuyRefundDispositionResponse(
        boolean processed,
        boolean alertResolved,
        String outcome,
        AdminGroupBuyFailedRefundResponse refund) {}
