package com.tuowei.dazhongdianping.module.topic.service;

import com.tuowei.dazhongdianping.module.topic.mapper.TopicMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicHotMetricRow;
import com.tuowei.dazhongdianping.module.topic.model.TopicHotSnapshotRow;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TopicHotRankingService {
    private final TopicMapper mapper;
    private final TopicHotSnapshotWriter snapshotWriter;

    public TopicHotRankingService(TopicMapper mapper, TopicHotSnapshotWriter snapshotWriter) {
        this.mapper = mapper;
        this.snapshotWriter = snapshotWriter;
    }

    @Transactional
    public void recalculateRegion(String region) {
        List<Long> topicIds = mapper.selectPublicTopicIds(region);
        mapper.deleteInvalidHotSnapshots(region);
        replace(region, topicIds);
    }

    @Transactional
    public void recalculateDirtyRegion(String region) {
        mapper.deleteInvalidHotSnapshots(region);
        replace(region, mapper.selectDirtyPublicTopicIds(region));
    }

    @Transactional
    public void ensureRegionSnapshot(String region) {
        if (mapper.countPublicTopics(region, "hot") > 0 && mapper.countRegionHotSnapshots(region) == 0) {
            recalculateRegion(region);
        }
    }

    private void replace(String region, List<Long> topicIds) {
        if (topicIds == null || topicIds.isEmpty()) return;
        LocalDateTime calculatedAt = LocalDateTime.now();
        List<TopicHotSnapshotRow> snapshots = mapper.selectHotMetrics(
                        region, calculatedAt.minusDays(7), topicIds)
                .stream()
                .map(metric -> snapshot(metric, calculatedAt))
                .toList();
        snapshotWriter.replaceTopics(new LinkedHashSet<>(topicIds), snapshots);
    }

    private TopicHotSnapshotRow snapshot(TopicHotMetricRow metric, LocalDateTime calculatedAt) {
        TopicHotSnapshotRow row = new TopicHotSnapshotRow();
        row.setTopicId(metric.getTopicId());
        row.setRegion(metric.getRegion());
        row.setPostCount7d(value(metric.getPostCount7d()));
        row.setLikeCount7d(value(metric.getLikeCount7d()));
        row.setCommentCount7d(value(metric.getCommentCount7d()));
        row.setScore(score(metric));
        row.setCalculatedAt(calculatedAt);
        return row;
    }

    private long score(TopicHotMetricRow row) {
        return value(row.getPostCount7d()) * 20L
                + value(row.getLikeCount7d()) * 3L
                + value(row.getCommentCount7d()) * 5L
                + (Boolean.TRUE.equals(row.getRecommended()) ? 100L : 0L);
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }
}
