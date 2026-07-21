package com.tuowei.dazhongdianping.module.browse.model.response;

import com.tuowei.dazhongdianping.module.auth.model.response.UserExpertCertificationBadgeResponse;
import com.tuowei.dazhongdianping.module.review.model.response.MerchantReplyResponse;
import java.math.BigDecimal;

public record ReviewPreviewResponse(
        Long id,
        String userName,
        UserExpertCertificationBadgeResponse authorCertification,
        BigDecimal score,
        String content,
        Integer likedCount,
        Integer commentCount,
        MerchantReplyResponse merchantReply,
        String createdAt
) {
}
