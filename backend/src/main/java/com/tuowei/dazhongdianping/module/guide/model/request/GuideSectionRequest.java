package com.tuowei.dazhongdianping.module.guide.model.request;

import jakarta.validation.constraints.Size;

public record GuideSectionRequest(
        @Size(max = 128) String heading,
        @Size(max = 4000) String body,
        Long shopId,
        Integer sortNo
) {
}
