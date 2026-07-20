package com.tuowei.dazhongdianping.module.topic.model.response;

public record TopicFollowResponse(Long topicId, boolean followed, Integer followerCount) {
}
