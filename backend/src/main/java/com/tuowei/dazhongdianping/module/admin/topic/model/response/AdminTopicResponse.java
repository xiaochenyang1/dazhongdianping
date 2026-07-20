package com.tuowei.dazhongdianping.module.admin.topic.model.response;

public record AdminTopicResponse(
        Long id,
        String region,
        String name,
        Integer postCount,
        Integer followerCount,
        Boolean recommended,
        Integer pinnedSort,
        Integer status,
        Long mergedToId,
        Long hotScore,
        Integer postCount7d,
        Integer likeCount7d,
        Integer commentCount7d,
        String calculatedAt
) {
}
