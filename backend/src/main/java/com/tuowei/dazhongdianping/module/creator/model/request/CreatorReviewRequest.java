package com.tuowei.dazhongdianping.module.creator.model.request;

import jakarta.validation.constraints.*;

public record CreatorReviewRequest(
        @NotNull Boolean approved,
        @NotNull @Positive Integer submissionVersion,
        @Pattern(regexp = "[a-f0-9]{64}") String evidenceHash,
        @Size(max = 1000) String note
) {}
