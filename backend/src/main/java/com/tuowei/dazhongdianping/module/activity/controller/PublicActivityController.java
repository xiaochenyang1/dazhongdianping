package com.tuowei.dazhongdianping.module.activity.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.activity.model.response.PublicActivityDetailResponse;
import com.tuowei.dazhongdianping.module.activity.model.response.PublicActivitySummaryResponse;
import com.tuowei.dazhongdianping.module.activity.service.PublicActivityService;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1/activities")
public class PublicActivityController {

    private final PublicActivityService publicActivityService;

    public PublicActivityController(PublicActivityService publicActivityService) {
        this.publicActivityService = publicActivityService;
    }

    @GetMapping
    public ApiResponse<List<PublicActivitySummaryResponse>> list(
            @RequestParam(required = false) Long cityId,
            @RequestParam(required = false) Integer channel,
            @RequestParam(required = false)
            @Min(value = 1, message = "limit 最小为 1")
            @Max(value = 50, message = "limit 最大为 50") Integer limit) {
        return ApiResponse.success(publicActivityService.list(RegionContext.getRegion(), cityId, channel, limit));
    }

    @GetMapping("/{activityId}")
    public ApiResponse<PublicActivityDetailResponse> detail(@PathVariable Long activityId) {
        return ApiResponse.success(publicActivityService.detail(RegionContext.getRegion(), activityId));
    }
}
