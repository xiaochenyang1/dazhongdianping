package com.tuowei.dazhongdianping.module.admin.audit.scheduler;

import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueMetricRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueOverdueRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueSlaThreshold;
import com.tuowei.dazhongdianping.module.admin.audit.service.AdminAuditService;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class AdminAuditSlaReminderScheduler {

    private static final Logger log = LoggerFactory.getLogger(AdminAuditSlaReminderScheduler.class);

    private final AdminAuditMapper adminAuditMapper;
    private final AdminAuditService adminAuditService;

    public AdminAuditSlaReminderScheduler(AdminAuditMapper adminAuditMapper, AdminAuditService adminAuditService) {
        this.adminAuditMapper = adminAuditMapper;
        this.adminAuditService = adminAuditService;
    }

    @Scheduled(fixedDelayString = "${app.admin.audit.sla.reminder-interval-ms:60000}")
    public void refreshSlaAlerts() {
        List<AuditQueueSlaThreshold> thresholds = adminAuditService.moderationSlaThresholds();
        List<Integer> bizTypes = thresholds.stream().map(AuditQueueSlaThreshold::bizType).toList();
        for (Region region : Region.values()) {
            try {
                refreshRegion(region.name(), bizTypes, thresholds);
            } catch (RuntimeException exception) {
                log.error("admin audit SLA alert refresh failed for region {}", region, exception);
            }
        }
    }

    private void refreshRegion(String region, List<Integer> bizTypes, List<AuditQueueSlaThreshold> thresholds) {
        Map<Integer, AuditQueueMetricRow> metricsByType = adminAuditMapper
                .selectModerationQueueMetrics(region, bizTypes)
                .stream()
                .collect(Collectors.toMap(AuditQueueMetricRow::getBizType, Function.identity()));
        Map<Integer, Long> overdueCountsByType = adminAuditMapper
                .selectModerationQueueOverdueCounts(region, bizTypes, thresholds)
                .stream()
                .collect(Collectors.toMap(AuditQueueOverdueRow::getBizType, row -> row.getOverdueCount() == null ? 0L : row.getOverdueCount()));

        for (Integer bizType : bizTypes) {
            AuditQueueMetricRow metric = metricsByType.get(bizType);
            long overdueCount = overdueCountsByType.getOrDefault(bizType, 0L);
            if (metric != null && overdueCount > 0 && metric.getOldestPendingAt() != null) {
                adminAuditMapper.upsertAdminAuditSlaAlert(
                        region,
                        bizType,
                        metric.getPendingCount() == null ? 0L : metric.getPendingCount(),
                        overdueCount,
                        metric.getOldestPendingAt()
                );
            } else {
                adminAuditMapper.resolveAdminAuditSlaAlert(region, bizType);
            }
        }
    }
}
