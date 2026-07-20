package com.tuowei.dazhongdianping.module.community.model.response;

public record PostReportResponse(
        Long id, Long postId, String reason, Integer status, String statusText, String createdAt
) {
}
