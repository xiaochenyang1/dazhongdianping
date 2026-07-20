package com.tuowei.dazhongdianping.module.merchant.review.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.merchant.review.model.request.MerchantReviewAppealSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.review.model.request.MerchantReviewReplyRequest;
import com.tuowei.dazhongdianping.module.merchant.review.service.MerchantReviewService;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1")
public class MerchantReviewController {

    private final MerchantReviewService service;

    public MerchantReviewController(MerchantReviewService service) {
        this.service = service;
    }

    @GetMapping("/reviews")
    public ApiResponse<PageResult<Map<String, Object>>> reviews(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Integer replyStatus,
            @RequestParam(required = false) Integer appealStatus,
            @RequestParam(required = false) Integer score,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) LocalDate dateFrom,
            @RequestParam(required = false) LocalDate dateTo,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(service.reviews(
                shopId, replyStatus, appealStatus, score, keyword, dateFrom, dateTo, page, pageSize
        ));
    }

    @PutMapping("/reviews/{reviewId}/reply")
    public ApiResponse<Map<String, Object>> saveReply(
            @PathVariable Long reviewId,
            @Valid @RequestBody MerchantReviewReplyRequest request
    ) {
        return ApiResponse.success("商家回复已保存", "merchant.review_reply_saved",
                service.saveReply(reviewId, request));
    }

    @PostMapping("/reviews/{reviewId}/appeal-drafts")
    public ApiResponse<Map<String, Object>> createAppealDraft(@PathVariable Long reviewId) {
        return ApiResponse.success("点评申诉草稿已创建", "merchant.review_appeal_draft_created",
                service.createAppealDraft(reviewId));
    }

    @PutMapping("/review-appeals/{appealId}")
    public ApiResponse<Map<String, Object>> saveAppeal(
            @PathVariable Long appealId,
            @Valid @RequestBody MerchantReviewAppealSaveRequest request
    ) {
        return ApiResponse.success("点评申诉已保存", "merchant.review_appeal_saved",
                service.saveAppeal(appealId, request));
    }

    @PostMapping("/review-appeals/{appealId}/submit")
    public ApiResponse<Map<String, Object>> submitAppeal(@PathVariable Long appealId) {
        return ApiResponse.success("点评申诉已提交审核", "merchant.review_appeal_submitted",
                service.submitAppeal(appealId));
    }
}
