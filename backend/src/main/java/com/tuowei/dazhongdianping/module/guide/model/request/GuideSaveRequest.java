package com.tuowei.dazhongdianping.module.guide.model.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record GuideSaveRequest(
        @NotBlank(message = "title 不能为空") @Size(max = 128) String title,
        @Size(max = 500) String summary,
        @Size(max = 255) String coverUrl,
        Long cityId,
        Integer status,
        @Valid List<GuideSectionRequest> sections
) {
}
