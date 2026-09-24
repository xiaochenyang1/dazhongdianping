package com.tuowei.dazhongdianping.module.recommendation.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.recommendation.model.request.BehaviorEventRequest;
import com.tuowei.dazhongdianping.module.recommendation.service.RecommendationService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/recommendations")
public class RecommendationController {

    private final RecommendationService service;

    public RecommendationController(RecommendationService service) {
        this.service = service;
    }

    /** 猜你喜欢 feed（匿名可用；登录后基于行为个性化）。 */
    @GetMapping("/feed")
    public ApiResponse<List<ShopListItemResponse>> feed(
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(required = false) Long cityId,
            @RequestParam(defaultValue = "12") Integer limit) {
        int safeLimit = Math.min(Math.max(limit == null ? 12 : limit, 1), 50);
        return ApiResponse.success(service.feed(latitude, longitude, cityId, safeLimit));
    }

    /** 上报用户行为埋点（需登录）。 */
    @PostMapping("/behaviors")
    public ApiResponse<Void> track(@Valid @RequestBody BehaviorEventRequest request) {
        service.trackBehavior(request);
        return ApiResponse.success("上报成功", "recommendation.behavior_tracked", null);
    }
}
