package com.tuowei.dazhongdianping.module.review.mapper;

import com.tuowei.dazhongdianping.module.review.model.ReviewImageRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewListQuery;
import com.tuowei.dazhongdianping.module.review.model.ReviewCommentListQuery;
import com.tuowei.dazhongdianping.module.review.model.ReviewCommentRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewLikeRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewReportRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.ReviewMerchantReplyRow;
import java.math.BigDecimal;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface ReviewMapper {

    int countAvailableShop(@Param("region") String region, @Param("shopId") Long shopId);

    void insertReview(ReviewRow row);

    void insertReviewImage(ReviewImageRow row);

    ReviewRow selectReviewById(@Param("reviewId") Long reviewId);

    ReviewRow selectOwnedReviewById(@Param("reviewId") Long reviewId,
                                    @Param("userId") Long userId,
                                    @Param("region") String region);

    ReviewRow selectPublicReviewById(@Param("reviewId") Long reviewId, @Param("region") String region);

    List<ReviewImageRow> selectReviewImages(@Param("reviewId") Long reviewId);

    ReviewMerchantReplyRow selectMerchantReply(@Param("reviewId") Long reviewId);

    int updateReview(ReviewRow row);

    int deleteReviewImagesByReviewId(@Param("reviewId") Long reviewId);

    int softDeleteReview(@Param("reviewId") Long reviewId, @Param("userId") Long userId);

    int updateReviewAuditDecision(@Param("reviewId") Long reviewId,
                                  @Param("auditStatus") Integer auditStatus,
                                  @Param("auditRemark") String auditRemark);

    void insertReviewLike(ReviewLikeRow row);

    int deleteReviewLike(@Param("reviewId") Long reviewId, @Param("userId") Long userId);

    int countReviewLikes(@Param("reviewId") Long reviewId);

    int countUserReviewLike(@Param("reviewId") Long reviewId, @Param("userId") Long userId);

    void insertReviewComment(ReviewCommentRow row);

    long countPublicRootReviewComments(@Param("reviewId") Long reviewId);

    List<ReviewCommentRow> selectPublicRootReviewComments(ReviewCommentListQuery query);

    List<ReviewCommentRow> selectPublicReviewCommentReplies(@Param("reviewId") Long reviewId,
                                                            @Param("parentIds") List<Long> parentIds);

    ReviewCommentRow selectPublicReviewCommentById(@Param("reviewId") Long reviewId,
                                                   @Param("commentId") Long commentId);

    void insertReviewReport(ReviewReportRow row);

    ReviewReportRow selectReviewReportByReporter(@Param("reviewId") Long reviewId,
                                                 @Param("reporterUserId") Long reporterUserId);

    int resolvePendingReviewReports(@Param("reviewId") Long reviewId);

    int countReviewComments(@Param("reviewId") Long reviewId);

    int updateReviewInteractionCounts(@Param("reviewId") Long reviewId,
                                      @Param("likeCount") Integer likeCount,
                                      @Param("commentCount") Integer commentCount);

    long countUserReviews(ReviewListQuery query);

    List<ReviewRow> selectUserReviews(ReviewListQuery query);

    List<ReviewRow> selectApprovedReviewsForAggregation(@Param("shopId") Long shopId);

    int updateShopReviewAggregate(@Param("shopId") Long shopId,
                                  @Param("score") BigDecimal score,
                                  @Param("tasteScore") BigDecimal tasteScore,
                                  @Param("envScore") BigDecimal envScore,
                                  @Param("serviceScore") BigDecimal serviceScore,
                                  @Param("reviewCount") Integer reviewCount);
}
