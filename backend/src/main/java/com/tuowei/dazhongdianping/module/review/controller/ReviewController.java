package com.tuowei.dazhongdianping.module.review.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.review.model.ReviewCommentListQuery;
import com.tuowei.dazhongdianping.module.review.model.ReviewListQuery;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewCommentCreateRequest;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewReportRequest;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewSaveRequest;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewCommentResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewDetailResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewLikeResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewReportResponse;
import com.tuowei.dazhongdianping.module.review.model.response.UserReviewSummaryResponse;
import com.tuowei.dazhongdianping.module.review.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping("/reviews")
    public ApiResponse<ReviewDetailResponse> createReview(@Valid @RequestBody ReviewSaveRequest request) {
        return ApiResponse.success("点评提交成功，等待审核", "review.created", reviewService.createReview(request));
    }

    @GetMapping("/reviews/{reviewId}")
    public ApiResponse<ReviewDetailResponse> getReview(@PathVariable Long reviewId) {
        return ApiResponse.success(reviewService.getPublicReviewDetail(reviewId));
    }

    @PostMapping("/reviews/{reviewId}/like")
    public ApiResponse<ReviewLikeResponse> toggleLike(@PathVariable Long reviewId) {
        ReviewLikeResponse response = reviewService.toggleLike(reviewId);
        String message = response.liked() ? "点赞成功" : "已取消点赞";
        String messageKey = response.liked() ? "review.like_on" : "review.like_off";
        return ApiResponse.success(message, messageKey, response);
    }

    @PostMapping("/reviews/{reviewId}/comments")
    public ApiResponse<ReviewCommentResponse> createComment(@PathVariable Long reviewId,
                                                            @Valid @RequestBody ReviewCommentCreateRequest request) {
        return ApiResponse.success("评论已发布", "review.comment_created", reviewService.createComment(reviewId, request));
    }

    @GetMapping("/reviews/{reviewId}/comments")
    public ApiResponse<PageResult<ReviewCommentResponse>> listComments(@PathVariable Long reviewId,
                                                                       @Valid ReviewCommentListQuery query) {
        return ApiResponse.success(reviewService.listComments(reviewId, query));
    }

    @PostMapping("/reviews/{reviewId}/report")
    public ApiResponse<ReviewReportResponse> reportReview(@PathVariable Long reviewId,
                                                          @Valid @RequestBody ReviewReportRequest request) {
        return ApiResponse.success("举报已提交，等待审核", "review.reported", reviewService.reportReview(reviewId, request));
    }

    @GetMapping("/user/reviews/{reviewId}")
    public ApiResponse<ReviewDetailResponse> getUserReview(@PathVariable Long reviewId) {
        return ApiResponse.success(reviewService.getOwnedReviewDetail(reviewId));
    }

    @PutMapping("/reviews/{reviewId}")
    public ApiResponse<ReviewDetailResponse> updateReview(@PathVariable Long reviewId,
                                                          @Valid @RequestBody ReviewSaveRequest request) {
        return ApiResponse.success("点评已更新并重新进入审核", "review.updated", reviewService.updateReview(reviewId, request));
    }

    @DeleteMapping("/reviews/{reviewId}")
    public ApiResponse<Void> deleteReview(@PathVariable Long reviewId) {
        reviewService.deleteReview(reviewId);
        return ApiResponse.success("点评已删除", "review.deleted", null);
    }

    @GetMapping("/user/reviews")
    public ApiResponse<PageResult<UserReviewSummaryResponse>> listUserReviews(@Valid ReviewListQuery query) {
        return ApiResponse.success(reviewService.listUserReviews(query));
    }
}
