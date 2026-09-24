package com.tuowei.dazhongdianping.module.dishreview.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.dishreview.model.request.DishReviewCreateRequest;
import com.tuowei.dazhongdianping.module.dishreview.service.DishReviewService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/shops/{shopId}/dishes/{dishId}/reviews")
public class DishReviewController {

    private final DishReviewService service;

    public DishReviewController(DishReviewService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> list(
            @PathVariable Long shopId, @PathVariable Long dishId) {
        return ApiResponse.success(service.list(shopId, dishId));
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> create(
            @PathVariable Long shopId,
            @PathVariable Long dishId,
            @Valid @RequestBody DishReviewCreateRequest request) {
        return ApiResponse.success(
                "菜品点评已发布",
                "dishreview.created",
                service.create(shopId, dishId, request.score(), request.content()));
    }
}
