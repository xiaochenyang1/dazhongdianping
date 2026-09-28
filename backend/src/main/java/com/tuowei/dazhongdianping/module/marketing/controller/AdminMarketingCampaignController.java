package com.tuowei.dazhongdianping.module.marketing.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.marketing.model.request.CampaignAuditRequest;
import com.tuowei.dazhongdianping.module.marketing.service.AdminMarketingCampaignService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/marketing")
public class AdminMarketingCampaignController {

    private final AdminMarketingCampaignService service;

    public AdminMarketingCampaignController(AdminMarketingCampaignService service) {
        this.service = service;
    }

    @GetMapping("/seckill")
    @AdminPermission("operations:marketing:read")
    public ApiResponse<List<Map<String, Object>>> seckills() {
        return ApiResponse.success(service.listSeckills());
    }

    @GetMapping("/groupbuy")
    @AdminPermission("operations:marketing:read")
    public ApiResponse<List<Map<String, Object>>> groupBuys() {
        return ApiResponse.success(service.listGroups());
    }

    @PostMapping("/seckill/{id}/audit")
    @AdminPermission("operations:marketing:write")
    public ApiResponse<Map<String, Object>> auditSeckill(
            @PathVariable Long id, @Valid @RequestBody CampaignAuditRequest request) {
        return ApiResponse.success("审核完成", "admin.marketing_seckill_audited", service.auditSeckill(id, request));
    }

    @PostMapping("/groupbuy/{id}/audit")
    @AdminPermission("operations:marketing:write")
    public ApiResponse<Map<String, Object>> auditGroupBuy(
            @PathVariable Long id, @Valid @RequestBody CampaignAuditRequest request) {
        return ApiResponse.success("审核完成", "admin.marketing_groupbuy_audited", service.auditGroupBuy(id, request));
    }
}
