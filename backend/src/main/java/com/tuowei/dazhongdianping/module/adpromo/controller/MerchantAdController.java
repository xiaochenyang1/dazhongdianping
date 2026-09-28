package com.tuowei.dazhongdianping.module.adpromo.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.adpromo.model.request.AdCampaignSaveRequest;
import com.tuowei.dazhongdianping.module.adpromo.service.MerchantAdService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1/ads")
public class MerchantAdController {

    private final MerchantAdService service;

    public MerchantAdController(MerchantAdService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> campaigns(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.campaigns(page, pageSize));
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody AdCampaignSaveRequest request) {
        return ApiResponse.success("广告投放已创建，待平台审核", "merchant.ad_created", service.create(request));
    }

    @PutMapping("/{id}")
    public ApiResponse<Map<String, Object>> update(
            @PathVariable Long id, @Valid @RequestBody AdCampaignSaveRequest request) {
        return ApiResponse.success("广告投放已更新，待重新审核", "merchant.ad_saved", service.update(id, request));
    }

    @PostMapping("/{id}/pause")
    public ApiResponse<Map<String, Object>> pause(@PathVariable Long id) {
        return ApiResponse.success("已暂停投放", "merchant.ad_paused", service.setStatus(id, 2));
    }

    @PostMapping("/{id}/resume")
    public ApiResponse<Map<String, Object>> resume(@PathVariable Long id) {
        return ApiResponse.success("已恢复投放", "merchant.ad_resumed", service.setStatus(id, 1));
    }

    @GetMapping("/report")
    public ApiResponse<Map<String, Object>> report(@RequestParam Long shopId) {
        return ApiResponse.success(service.report(shopId));
    }
}
