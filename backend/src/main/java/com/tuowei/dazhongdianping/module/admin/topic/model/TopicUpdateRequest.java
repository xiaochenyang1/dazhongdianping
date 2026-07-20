package com.tuowei.dazhongdianping.module.admin.topic.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TopicUpdateRequest(@NotBlank @Size(max = 64) String name) {
}
