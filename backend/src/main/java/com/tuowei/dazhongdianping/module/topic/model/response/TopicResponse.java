package com.tuowei.dazhongdianping.module.topic.model.response;

public record TopicResponse(
        Long id,
        String region,
        String name,
        Integer postCount,
        Integer followerCount,
        Boolean recommended,
        Integer pinnedSort,
        Boolean followedByCurrentUser,
        Long hotScore,
        Integer postCount7d,
        Integer likeCount7d,
        Integer commentCount7d,
        String calculatedAt
) {
}
