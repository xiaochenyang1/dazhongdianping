package com.tuowei.dazhongdianping.module.recommendation.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.recommendation.model.request.RecommendationWeightSaveRequest;
import com.tuowei.dazhongdianping.module.recommendation.model.response.RecommendationWeightResponse;
import com.tuowei.dazhongdianping.module.recommendation.service.AdminRecommendationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/recommendation/weight")
public class AdminRecommendationController {

    private final AdminRecommendationService service;

    public AdminRecommendationController(AdminRecommendationService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:recommendation:read")
    public ApiResponse<RecommendationWeightResponse> current() {
        return ApiResponse.success(service.currentWeight());
    }

    @PutMapping
    @AdminPermission("operations:recommendation:write")
    public ApiResponse<RecommendationWeightResponse> save(@Valid @RequestBody RecommendationWeightSaveRequest request) {
        return ApiResponse.success("保存成功", "admin.recommendation_weight_saved", service.saveWeight(request));
    }
}
