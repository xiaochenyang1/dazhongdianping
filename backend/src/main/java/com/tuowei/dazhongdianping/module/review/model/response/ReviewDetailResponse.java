package com.tuowei.dazhongdianping.module.review.model.response;

import com.tuowei.dazhongdianping.module.auth.model.response.UserExpertCertificationBadgeResponse;
import java.math.BigDecimal;
import java.util.List;

public record ReviewDetailResponse(
        Long id,
        Long shopId,
        String shopName,
        Long userId,
        String userName,
        String content,
        BigDecimal scoreOverall,
        BigDecimal scoreTaste,
        BigDecimal scoreEnv,
        BigDecimal scoreService,
        BigDecimal cost,
        String currency,
        Integer likeCount,
        Integer commentCount,
        Boolean likedByCurrentUser,
        Integer auditStatus,
        String auditStatusText,
        String auditRemark,
        Integer status,
        String statusText,
        UserExpertCertificationBadgeResponse authorCertification,
        List<String> tags,
        List<ReviewImageResponse> images,
        MerchantReplyResponse merchantReply,
        String createdAt,
        String updatedAt
) {
}
