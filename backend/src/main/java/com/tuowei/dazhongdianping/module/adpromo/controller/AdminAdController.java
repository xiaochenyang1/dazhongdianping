package com.tuowei.dazhongdianping.module.adpromo.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.adpromo.model.request.AdAuditRequest;
import com.tuowei.dazhongdianping.module.adpromo.service.AdminAdService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/ads")
public class AdminAdController {

    private final AdminAdService service;

    public AdminAdController(AdminAdService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:ad:read")
    public ApiResponse<PageResult<Map<String, Object>>> campaigns(
            @RequestParam(required = false) Integer auditStatus,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.campaigns(auditStatus, page, pageSize));
    }

    @PostMapping("/{id}/audit")
    @AdminPermission("operations:ad:write")
    public ApiResponse<Map<String, Object>> audit(
            @PathVariable Long id, @Valid @RequestBody AdAuditRequest request) {
        return ApiResponse.success("审核完成", "admin.ad_audited", service.audit(id, request));
    }
}
