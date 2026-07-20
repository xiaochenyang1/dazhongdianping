package com.tuowei.dazhongdianping.module.admin.circle.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CircleSaveRequest(@NotBlank @Size(min = 2, max = 64) String name,
                                @Size(max = 500) String description,
                                @Size(max = 255) String coverUrl,
                                Integer sort) {}
