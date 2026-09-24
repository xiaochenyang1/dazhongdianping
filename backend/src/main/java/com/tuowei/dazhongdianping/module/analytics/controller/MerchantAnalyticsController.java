package com.tuowei.dazhongdianping.module.analytics.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.analytics.service.MerchantAnalyticsService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1/analytics")
public class MerchantAnalyticsController {

    private final MerchantAnalyticsService service;

    public MerchantAnalyticsController(MerchantAnalyticsService service) {
        this.service = service;
    }

    @GetMapping("/trend")
    public ApiResponse<Map<String, Object>> trend(
            @RequestParam Long shopId, @RequestParam(defaultValue = "7") Integer days) {
        return ApiResponse.success(service.trend(shopId, days));
    }

    @GetMapping("/export")
    public ApiResponse<String> export(
            @RequestParam Long shopId, @RequestParam(defaultValue = "7") Integer days) {
        return ApiResponse.success(service.export(shopId, days));
    }
}
