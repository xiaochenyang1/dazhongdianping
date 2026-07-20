package com.tuowei.dazhongdianping.module.community.model.response;

import java.util.List;

public record PostResponse(
        Long id,
        Long userId,
        Long circleId,
        String circleName,
        String userName,
        String title,
        String content,
        Integer contentType,
        Long shopId,
        Long dealId,
        Integer likeCount,
        Integer commentCount,
        Integer auditStatus,
        String auditStatusText,
        String auditRemark,
        Integer status,
        List<String> images,
        List<String> topics,
        String createdAt,
        String updatedAt
) {
}
