package com.tuowei.dazhongdianping.module.experiment.model.request;

import jakarta.validation.constraints.NotBlank;

public record ExperimentAssignRequest(
        @NotBlank(message = "variant 不能为空") String variant
) {
}
