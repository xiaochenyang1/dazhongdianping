package com.tuowei.dazhongdianping.module.marketing.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.marketing.model.request.GroupBuySaveRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.MerchantCouponCreateRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.SeckillSaveRequest;
import com.tuowei.dazhongdianping.module.marketing.service.MerchantMarketingService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1/marketing")
public class MerchantMarketingController {

    private final MerchantMarketingService service;

    public MerchantMarketingController(MerchantMarketingService service) {
        this.service = service;
    }

    @GetMapping("/coupons")
    public ApiResponse<List<Map<String, Object>>> coupons() {
        return ApiResponse.success(service.coupons());
    }

    @PostMapping("/coupons")
    public ApiResponse<Map<String, Object>> createCoupon(@Valid @RequestBody MerchantCouponCreateRequest request) {
        return ApiResponse.success("优惠券已提交审核", "merchant.coupon_created", service.createCoupon(request));
    }

    @GetMapping("/seckill")
    public ApiResponse<List<Map<String, Object>>> seckills(@RequestParam Long shopId) {
        return ApiResponse.success(service.seckills(shopId));
    }

    @PostMapping("/seckill")
    public ApiResponse<Map<String, Object>> createSeckill(@Valid @RequestBody SeckillSaveRequest request) {
        return ApiResponse.success("秒杀已提交审核", "merchant.seckill_created", service.createSeckill(request));
    }

    @GetMapping("/groupbuy")
    public ApiResponse<List<Map<String, Object>>> groupBuys(@RequestParam Long shopId) {
        return ApiResponse.success(service.groupBuys(shopId));
    }

    @PostMapping("/groupbuy")
    public ApiResponse<Map<String, Object>> createGroupBuy(@Valid @RequestBody GroupBuySaveRequest request) {
        return ApiResponse.success("拼团已提交审核", "merchant.groupbuy_created", service.createGroupBuy(request));
    }
}
