package com.tuowei.dazhongdianping.module.review.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReviewCommentCreateRequest {

    @NotBlank(message = "content 不能为空")
    @Size(max = 300, message = "content 不能超过 300 字")
    private String content;
}
