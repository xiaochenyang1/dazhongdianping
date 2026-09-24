package com.tuowei.dazhongdianping.module.experiment.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ExperimentSaveRequest(
        @NotBlank(message = "name 不能为空") @Size(max = 128) String name,
        @Size(max = 64) String flagKey,
        Integer status
) {
}
