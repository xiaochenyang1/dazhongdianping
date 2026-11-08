package com.tuowei.dazhongdianping.module.admin.groupbuy.model.request;

public record AdminGroupBuyRefundDispositionRequest(
        String outcome,
        String providerReference,
        String note) {}
