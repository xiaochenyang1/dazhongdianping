package com.tuowei.dazhongdianping.module.community.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record PostSaveRequest(
        Long circleId,
        @NotBlank(message = "title 不能为空")
        @Size(max = 80, message = "title 不能超过 80 字")
        String title,
        @NotBlank(message = "content 不能为空")
        @Size(max = 5000, message = "content 不能超过 5000 字")
        String content,
        @NotNull(message = "contentType 不能为空")
        @Min(value = 1, message = "contentType 仅支持 1 或 2")
        @Max(value = 2, message = "contentType 仅支持 1 或 2")
        Integer contentType,
        Long shopId,
        Long dealId,
        @Size(max = 9, message = "images 最多 9 张")
        List<@NotBlank(message = "图片地址不能为空") String> images,
        @Size(max = 5, message = "topics 最多 5 个")
        List<@NotBlank(message = "话题不能为空") @Size(max = 64, message = "话题不能超过 64 字") String> topics
) {
}
