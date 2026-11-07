package com.tuowei.dazhongdianping.module.marketing.service;

import static org.assertj.core.api.Assertions.assertThat;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

class GroupBuyMetricsTest {

    @Test
    void recordsLifecycleAndFailureWithBoundedTags() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        GroupBuyMetrics metrics = new GroupBuyMetrics(registry);

        metrics.teamOpened("CN");
        metrics.teamFormed("CN");
        metrics.automaticRefund("CN", false);
        metrics.failure("CN", "voucher_issuance");

        assertThat(counter(registry, "dianping.groupbuy.lifecycle", "event", "team_opened")).isEqualTo(1);
        assertThat(counter(registry, "dianping.groupbuy.lifecycle", "event", "team_formed")).isEqualTo(1);
        assertThat(counter(registry, "dianping.groupbuy.lifecycle", "event", "refund_pending_retry")).isEqualTo(1);
        assertThat(counter(registry, "dianping.groupbuy.failure", "stage", "voucher_issuance")).isEqualTo(1);
    }

    private double counter(SimpleMeterRegistry registry, String name, String tag, String value) {
        return registry.get(name).tag("region", "CN").tag(tag, value).counter().count();
    }
}
