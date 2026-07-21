package com.tuowei.dazhongdianping.module.admin.activity.model.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public record AdminOperationActivitySaveRequest(
        @NotBlank(message = "name 不能为空")
        @Size(max = 128, message = "name 不能超过 128 字")
        String name,
        @NotBlank(message = "code 不能为空")
        @Size(max = 64, message = "code 不能超过 64 字")
        @Pattern(regexp = "^[A-Za-z0-9_-]+$", message = "code 仅支持字母、数字、下划线和中划线")
        String code,
        @Min(value = 0, message = "cityId 不能小于 0")
        Long cityId,
        @NotNull(message = "channel 不能为空")
        @Min(value = 1, message = "channel 仅支持 1 到 5")
        @Max(value = 5, message = "channel 仅支持 1 到 5")
        Integer channel,
        @NotNull(message = "type 不能为空")
        @Min(value = 1, message = "type 仅支持 1 到 5")
        @Max(value = 5, message = "type 仅支持 1 到 5")
        Integer type,
        @NotBlank(message = "cover 不能为空")
        @Size(max = 255, message = "cover 不能超过 255 字")
        String cover,
        @NotBlank(message = "landingUrl 不能为空")
        @Size(max = 255, message = "landingUrl 不能超过 255 字")
        String landingUrl,
        JsonNode rule,
        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        LocalDateTime startAt,
        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        LocalDateTime endAt
) {
}
