package com.tuowei.dazhongdianping.module.message.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(@NotNull Long toUserId, @NotBlank @Size(max = 2000) String content) {}
