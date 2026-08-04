package com.tuowei.dazhongdianping.module.points.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.points.model.response.PointsExchangeResponse;
import com.tuowei.dazhongdianping.module.points.model.response.PointsProductResponse;
import com.tuowei.dazhongdianping.module.points.service.PointsMallService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/points")
public class PublicPointsMallController {

    private final PointsMallService pointsMallService;

    public PublicPointsMallController(PointsMallService pointsMallService) {
        this.pointsMallService = pointsMallService;
    }

    @GetMapping("/products")
    public ApiResponse<PageResult<PointsProductResponse>> products(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(pointsMallService.products(page, pageSize));
    }

    @GetMapping("/products/{productId}")
    public ApiResponse<PointsProductResponse> product(@PathVariable Long productId) {
        return ApiResponse.success(pointsMallService.product(productId));
    }

    @PostMapping("/products/{productId}/exchange")
    public ApiResponse<PointsExchangeResponse> exchange(@PathVariable Long productId) {
        return ApiResponse.success("兑换成功", "points.exchanged", pointsMallService.exchange(productId));
    }

    @GetMapping("/exchanges")
    public ApiResponse<PageResult<PointsExchangeResponse>> myExchanges(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(pointsMallService.myExchanges(page, pageSize));
    }
}
