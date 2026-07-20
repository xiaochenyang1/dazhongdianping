package com.tuowei.dazhongdianping.module.merchant.review.mapper;

import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewAppealRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.ReviewMerchantReplyRow;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MerchantReviewMapper {

    long countReviews(@Param("merchantId") Long merchantId,
                      @Param("region") String region,
                      @Param("shopId") Long shopId,
                      @Param("scopedShopIds") List<Long> scopedShopIds,
                      @Param("replyStatus") Integer replyStatus,
                      @Param("appealStatus") Integer appealStatus,
                      @Param("score") Integer score,
                      @Param("keyword") String keyword,
                      @Param("dateFrom") LocalDate dateFrom,
                      @Param("dateToExclusive") LocalDate dateToExclusive);

    List<MerchantReviewRow> selectReviews(@Param("merchantId") Long merchantId,
                                          @Param("region") String region,
                                          @Param("shopId") Long shopId,
                                          @Param("scopedShopIds") List<Long> scopedShopIds,
                                          @Param("replyStatus") Integer replyStatus,
                                          @Param("appealStatus") Integer appealStatus,
                                          @Param("score") Integer score,
                                          @Param("keyword") String keyword,
                                          @Param("dateFrom") LocalDate dateFrom,
                                          @Param("dateToExclusive") LocalDate dateToExclusive,
                                          @Param("limit") Integer limit,
                                          @Param("offset") Integer offset);

    MerchantReviewRow selectPublicReviewInMerchantScope(@Param("reviewId") Long reviewId,
                                                        @Param("merchantId") Long merchantId,
                                                        @Param("region") String region);

    ReviewMerchantReplyRow selectReply(@Param("reviewId") Long reviewId);

    void insertReply(ReviewMerchantReplyRow row);

    int updateReply(@Param("reviewId") Long reviewId,
                    @Param("merchantId") Long merchantId,
                    @Param("operatorId") Long operatorId,
                    @Param("content") String content);

    MerchantReviewAppealRow selectAppeal(@Param("merchantId") Long merchantId,
                                         @Param("region") String region,
                                         @Param("appealId") Long appealId);

    MerchantReviewAppealRow selectAppealByReview(@Param("merchantId") Long merchantId,
                                                 @Param("region") String region,
                                                 @Param("reviewId") Long reviewId);

    MerchantReviewAppealRow selectPendingAppealForAudit(@Param("appealId") Long appealId,
                                                        @Param("region") String region);

    void insertAppeal(MerchantReviewAppealRow row);

    int resetRejectedAppeal(@Param("appealId") Long appealId,
                            @Param("merchantId") Long merchantId,
                            @Param("operatorId") Long operatorId);

    int updateAppealDraft(@Param("appealId") Long appealId,
                          @Param("merchantId") Long merchantId,
                          @Param("operatorId") Long operatorId,
                          @Param("reason") String reason,
                          @Param("evidenceUrls") String evidenceUrls);

    int submitAppeal(@Param("appealId") Long appealId,
                     @Param("merchantId") Long merchantId,
                     @Param("operatorId") Long operatorId,
                     @Param("baseReviewUpdatedAt") LocalDateTime baseReviewUpdatedAt);

    int approveAppeal(@Param("appealId") Long appealId,
                      @Param("region") String region,
                      @Param("auditBy") Long auditBy);

    int rejectAppeal(@Param("appealId") Long appealId,
                     @Param("region") String region,
                     @Param("auditBy") Long auditBy,
                     @Param("reason") String reason);

    int hideReviewForAppeal(@Param("reviewId") Long reviewId,
                            @Param("region") String region,
                            @Param("baseReviewUpdatedAt") LocalDateTime baseReviewUpdatedAt,
                            @Param("auditRemark") String auditRemark);

    List<Long> selectActiveAppealIdsByReview(@Param("reviewId") Long reviewId);

    int invalidateActiveAppealsByReview(@Param("reviewId") Long reviewId,
                                        @Param("remark") String remark);

    void insertOperationLog(@Param("merchantId") Long merchantId,
                            @Param("operatorId") Long operatorId,
                            @Param("action") String action,
                            @Param("targetType") String targetType,
                            @Param("targetId") Long targetId,
                            @Param("detail") String detail);
}
