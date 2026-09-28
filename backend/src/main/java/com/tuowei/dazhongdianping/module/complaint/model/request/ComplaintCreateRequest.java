package com.tuowei.dazhongdianping.module.complaint.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** C端发起投诉的请求。 */
public record ComplaintCreateRequest(
        @NotNull @Min(1) Long shopId,
        @Min(0) Long orderId,
        @NotNull @Min(1) @Max(5) Integer type,
        @NotBlank @Size(max = 128) String title,
        @NotBlank @Size(max = 2000) String content
) {
}
