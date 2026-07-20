package com.tuowei.dazhongdianping.module.topic.model;

import lombok.Data;

@Data
public class TopicHotMetricRow {
    private Long topicId;
    private String region;
    private Boolean recommended;
    private Integer postCount7d;
    private Integer likeCount7d;
    private Integer commentCount7d;
}
