package com.tuowei.dazhongdianping.module.complaint.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 商家申辩的请求。 */
public record ComplaintReplyRequest(
        @NotBlank @Size(max = 2000) String reply
) {
}
