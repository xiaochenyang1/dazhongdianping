package com.tuowei.dazhongdianping.module.marketing.service;

import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Low-cardinality operational metrics for the group-buy transaction lifecycle.
 * Successful events are emitted after commit so rolled-back transactions do not
 * inflate conversion or fulfilment rates.
 */
@Component
public class GroupBuyMetrics {

    private static final String LIFECYCLE = "dianping.groupbuy.lifecycle";
    private static final String FAILURE = "dianping.groupbuy.failure";

    private final MeterRegistry registry;

    public GroupBuyMetrics(MeterRegistry registry) {
        this.registry = registry;
    }

    public void teamOpened(String region) {
        success(region, "team_opened");
    }

    public void memberJoined(String region) {
        success(region, "member_joined");
    }

    public void inventoryReserved(String region) {
        success(region, "inventory_reserved");
    }

    public void paymentCompleted(String region) {
        success(region, "payment_completed");
    }

    public void teamFormed(String region) {
        success(region, "team_formed");
    }

    public void teamExpired(String region) {
        success(region, "team_expired");
    }

    public void voucherIssued(String region) {
        success(region, "voucher_issued");
    }

    public void automaticRefund(String region, boolean submitted) {
        success(region, submitted ? "refund_submitted" : "refund_pending_retry");
    }

    public void failure(String region, String stage) {
        registry.counter(FAILURE, "region", safe(region), "stage", safe(stage)).increment();
    }

    private void success(String region, String event) {
        Runnable increment = () -> registry.counter(
                LIFECYCLE, "region", safe(region), "event", event).increment();
        if (TransactionSynchronizationManager.isActualTransactionActive()
                && TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    increment.run();
                }
            });
            return;
        }
        increment.run();
    }

    private String safe(String value) {
        return value == null || value.isBlank() ? "unknown" : value;
    }
}
