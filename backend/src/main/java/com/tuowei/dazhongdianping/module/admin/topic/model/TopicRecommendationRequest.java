package com.tuowei.dazhongdianping.module.admin.topic.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record TopicRecommendationRequest(boolean recommended, @NotNull @Min(0) Integer pinnedSort) {
}
