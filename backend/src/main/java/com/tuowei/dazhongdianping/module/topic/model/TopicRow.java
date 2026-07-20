package com.tuowei.dazhongdianping.module.topic.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class TopicRow {
    private Long id;
    private String region;
    private String name;
    private Integer postCount;
    private Integer followerCount;
    private Boolean recommended;
    private Integer pinnedSort;
    private Long mergedToId;
    private Integer status;
    private boolean followedByCurrentUser;
    private Long hotScore;
    private Integer postCount7d;
    private Integer likeCount7d;
    private Integer commentCount7d;
    private LocalDateTime calculatedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
