package com.tuowei.dazhongdianping.module.admin.merchant.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.merchant.model.request.AdminMerchantAuditRequest;
import com.tuowei.dazhongdianping.module.admin.merchant.service.AdminMerchantApplicationService;
import jakarta.servlet.http.HttpServletRequest;
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
@RequestMapping("/api/admin/v1/merchant-applications")
public class AdminMerchantApplicationController {

    private final AdminMerchantApplicationService service;

    public AdminMerchantApplicationController(AdminMerchantApplicationService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("audit:merchant_application:read")
    public ApiResponse<PageResult<Map<String, Object>>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(service.list(status, page, pageSize));
    }

    @PostMapping("/{merchantId}/audit")
    @AdminPermission("audit:merchant_application:write")
    public ApiResponse<Map<String, Object>> audit(
            @PathVariable Long merchantId,
            @Valid @RequestBody AdminMerchantAuditRequest request,
            HttpServletRequest servletRequest
    ) {
        return ApiResponse.success(
                "审核完成",
                "admin.merchant_application_audited",
                service.audit(merchantId, request, servletRequest.getRemoteAddr())
        );
    }
}
