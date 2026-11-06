package com.tuowei.dazhongdianping.module.creator.model.request;

import jakarta.validation.constraints.*;

public record CreatorSubmissionRequest(
        @NotNull @Pattern(regexp = "review|post") String evidenceType,
        @NotNull @Positive Long evidenceId,
        @Size(max = 1000) String note
) {}
