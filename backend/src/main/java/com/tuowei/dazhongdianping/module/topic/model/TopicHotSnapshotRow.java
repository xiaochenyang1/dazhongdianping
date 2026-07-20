package com.tuowei.dazhongdianping.module.topic.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class TopicHotSnapshotRow {
    private Long id;
    private Long topicId;
    private String region;
    private Long score;
    private Integer postCount7d;
    private Integer likeCount7d;
    private Integer commentCount7d;
    private LocalDateTime calculatedAt;
}
