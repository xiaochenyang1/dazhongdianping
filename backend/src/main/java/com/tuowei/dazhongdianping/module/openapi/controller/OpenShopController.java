package com.tuowei.dazhongdianping.module.openapi.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.openapi.service.OpenShopService;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/open/v1")
public class OpenShopController {

    private final OpenShopService service;

    public OpenShopController(OpenShopService service) {
        this.service = service;
    }

    @GetMapping("/shops")
    public ApiResponse<List<Map<String, Object>>> shops(@RequestParam(required = false) Integer limit) {
        return ApiResponse.success(service.shops(limit));
    }

    @GetMapping("/reviews")
    public ApiResponse<List<Map<String, Object>>> reviews(
            @RequestParam(required = false) Long shopId, @RequestParam(required = false) Integer limit) {
        return ApiResponse.success(service.reviews(shopId, limit));
    }
}
