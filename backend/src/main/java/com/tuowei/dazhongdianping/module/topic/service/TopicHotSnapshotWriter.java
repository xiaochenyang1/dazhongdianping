package com.tuowei.dazhongdianping.module.topic.service;

import com.tuowei.dazhongdianping.module.topic.mapper.TopicMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicHotSnapshotRow;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TopicHotSnapshotWriter {
    private final TopicMapper mapper;

    public TopicHotSnapshotWriter(TopicMapper mapper) {
        this.mapper = mapper;
    }

    @Transactional
    public void replaceTopics(Set<Long> topicIds, List<TopicHotSnapshotRow> snapshots) {
        if (topicIds != null && !topicIds.isEmpty()) {
            mapper.deleteHotSnapshots(new ArrayList<>(topicIds));
        }
        for (TopicHotSnapshotRow snapshot : snapshots == null ? List.<TopicHotSnapshotRow>of() : snapshots) {
            mapper.insertHotSnapshot(snapshot);
        }
    }
}
