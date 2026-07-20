package com.tuowei.dazhongdianping.module.admin.topic.model;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record TopicMergeRequest(@NotNull @Positive Long targetTopicId) {
}
