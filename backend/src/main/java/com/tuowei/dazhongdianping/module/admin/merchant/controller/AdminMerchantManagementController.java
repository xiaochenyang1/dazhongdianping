package com.tuowei.dazhongdianping.module.admin.merchant.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.request.AdminMerchantStatusRequest;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantResponse;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantOperatorResponse;
import com.tuowei.dazhongdianping.module.admin.merchant.service.AdminMerchantManagementService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1/merchants")
public class AdminMerchantManagementController {

    private final AdminMerchantManagementService service;

    public AdminMerchantManagementController(AdminMerchantManagementService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("system:merchant:read")
    public ApiResponse<PageResult<AdminMerchantResponse>> list(@Valid AdminMerchantQuery query) {
        return ApiResponse.success(service.listMerchants(query));
    }

    @GetMapping("/{merchantId}")
    @AdminPermission("system:merchant:read")
    public ApiResponse<AdminMerchantResponse> detail(@PathVariable Long merchantId) {
        return ApiResponse.success(service.getMerchant(merchantId));
    }

    @GetMapping("/{merchantId}/operators")
    @AdminPermission("system:merchant:read")
    public ApiResponse<PageResult<AdminMerchantOperatorResponse>> operators(
            @PathVariable Long merchantId,
            @Valid AdminMerchantOperatorQuery query
    ) {
        return ApiResponse.success(service.listMerchantOperators(merchantId, query));
    }

    @GetMapping("/{merchantId}/operators/{operatorId}")
    @AdminPermission("system:merchant:read")
    public ApiResponse<AdminMerchantOperatorResponse> operatorDetail(
            @PathVariable Long merchantId,
            @PathVariable Long operatorId
    ) {
        return ApiResponse.success(service.getMerchantOperator(merchantId, operatorId));
    }

    @PutMapping("/{merchantId}/status")
    @AdminPermission("system:merchant:write")
    public ApiResponse<AdminMerchantResponse> updateStatus(
            @PathVariable Long merchantId,
            @Valid @RequestBody AdminMerchantStatusRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.updateMerchantStatus(
                merchantId,
                request,
                httpServletRequest.getRemoteAddr()
        ));
    }

    @PutMapping("/{merchantId}/operators/{operatorId}/status")
    @AdminPermission("system:merchant:write")
    public ApiResponse<AdminMerchantOperatorResponse> updateOperatorStatus(
            @PathVariable Long merchantId,
            @PathVariable Long operatorId,
            @Valid @RequestBody AdminMerchantStatusRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.updateMerchantOperatorStatus(
                merchantId,
                operatorId,
                request,
                httpServletRequest.getRemoteAddr()
        ));
    }
}
