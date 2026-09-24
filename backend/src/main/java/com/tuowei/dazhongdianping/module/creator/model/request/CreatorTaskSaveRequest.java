package com.tuowei.dazhongdianping.module.creator.model.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreatorTaskSaveRequest(
        @NotBlank(message = "title 不能为空") @Size(max = 128) String title,
        @Size(max = 1000) String description,
        @NotNull(message = "rewardPoints 不能为空") @Min(0) Integer rewardPoints,
        Integer status
) {
}
