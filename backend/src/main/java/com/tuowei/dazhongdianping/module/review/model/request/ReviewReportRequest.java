package com.tuowei.dazhongdianping.module.review.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReviewReportRequest {

    @NotBlank(message = "reason 不能为空")
    @Size(max = 200, message = "reason 不能超过 200 字")
    private String reason;
}
