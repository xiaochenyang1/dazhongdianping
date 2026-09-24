package com.tuowei.dazhongdianping.module.review.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewTranslationSaveRequest;
import com.tuowei.dazhongdianping.module.review.service.ReviewTranslationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/reviews/{reviewId}/translations")
public class ReviewTranslationController {

    private final ReviewTranslationService service;

    public ReviewTranslationController(ReviewTranslationService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> list(
            @PathVariable Long reviewId,
            @RequestParam(required = false) String lang) {
        return ApiResponse.success(service.list(reviewId, lang));
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> save(
            @PathVariable Long reviewId,
            @Valid @RequestBody ReviewTranslationSaveRequest request) {
        return ApiResponse.success(
                "翻译已保存",
                "review.translation_saved",
                service.save(reviewId, request.targetLang(), request.content()));
    }
}
