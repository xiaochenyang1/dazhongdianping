package com.tuowei.dazhongdianping.module.marketing.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.marketing.model.request.CampaignAuditRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.CouponTemplateSaveRequest;
import com.tuowei.dazhongdianping.module.marketing.model.response.CouponTemplateResponse;
import com.tuowei.dazhongdianping.module.marketing.service.AdminMarketingService;
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
@RequestMapping("/api/admin/v1/marketing/coupon-templates")
public class AdminMarketingController {

    private final AdminMarketingService service;

    public AdminMarketingController(AdminMarketingService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:marketing:read")
    public ApiResponse<PageResult<CouponTemplateResponse>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.templates(status, page, pageSize));
    }

    @PostMapping
    @AdminPermission("operations:marketing:write")
    public ApiResponse<CouponTemplateResponse> create(@Valid @RequestBody CouponTemplateSaveRequest request) {
        return ApiResponse.success("创建成功", "admin.marketing_coupon_created", service.create(request));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:marketing:write")
    public ApiResponse<CouponTemplateResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody CouponTemplateSaveRequest request) {
        return ApiResponse.success("保存成功", "admin.marketing_coupon_saved", service.update(id, request));
    }

    @PostMapping("/{id}/audit")
    @AdminPermission("operations:marketing:write")
    public ApiResponse<Map<String, Object>> audit(
            @PathVariable Long id, @Valid @RequestBody CampaignAuditRequest request) {
        return ApiResponse.success("审核完成", "admin.marketing_coupon_audited", service.audit(id, request));
    }
}
