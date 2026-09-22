package com.tuowei.dazhongdianping.module.waitlist.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.waitlist.service.MerchantWaitlistService;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1/waitlist")
public class MerchantWaitlistController {

    private final MerchantWaitlistService service;

    public MerchantWaitlistController(MerchantWaitlistService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<Map<String, Object>>> queue(@RequestParam Long shopId) {
        return ApiResponse.success(service.queue(shopId));
    }

    @PostMapping("/{id}/call")
    public ApiResponse<Map<String, Object>> call(@PathVariable Long id) {
        return ApiResponse.success("已叫号", "merchant.waitlist_called", service.call(id));
    }

    @PostMapping("/{id}/seat")
    public ApiResponse<Map<String, Object>> seat(@PathVariable Long id) {
        return ApiResponse.success("已入座", "merchant.waitlist_seated", service.seat(id));
    }

    @PostMapping("/{id}/pass")
    public ApiResponse<Map<String, Object>> pass(@PathVariable Long id) {
        return ApiResponse.success("已过号", "merchant.waitlist_passed", service.pass(id));
    }
}
