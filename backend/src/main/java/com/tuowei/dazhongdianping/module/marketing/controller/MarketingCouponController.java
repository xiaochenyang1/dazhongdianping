package com.tuowei.dazhongdianping.module.marketing.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.marketing.model.response.CouponCenterItemResponse;
import com.tuowei.dazhongdianping.module.marketing.model.response.UserCouponResponse;
import com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/marketing/coupons")
public class MarketingCouponController {

    private final MarketingCouponService service;

    public MarketingCouponController(MarketingCouponService service) {
        this.service = service;
    }

    /** 领券中心（匿名可看；登录后带领取状态）。 */
    @GetMapping("/center")
    public ApiResponse<List<CouponCenterItemResponse>> center() {
        return ApiResponse.success(service.couponCenter());
    }

    /** 领取一张券（需登录）。 */
    @PostMapping("/{templateId}/claim")
    public ApiResponse<UserCouponResponse> claim(@PathVariable Long templateId) {
        return ApiResponse.success("领取成功", "marketing.coupon_claimed", service.claim(templateId));
    }

    /** 我的营销券钱包（需登录）。 */
    @GetMapping("/mine")
    public ApiResponse<PageResult<UserCouponResponse>> mine(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.myCoupons(status, page, pageSize));
    }
}
