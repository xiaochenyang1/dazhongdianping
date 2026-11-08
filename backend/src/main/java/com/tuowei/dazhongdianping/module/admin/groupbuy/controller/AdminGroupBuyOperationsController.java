package com.tuowei.dazhongdianping.module.admin.groupbuy.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.request.AdminGroupBuyRefundDispositionRequest;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyFailedRefundResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyReconcileResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyRefundDispositionResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuySummaryResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyTeamResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.service.AdminGroupBuyOperationsService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/groupbuy/operations")
public class AdminGroupBuyOperationsController {

    private final AdminGroupBuyOperationsService service;

    public AdminGroupBuyOperationsController(AdminGroupBuyOperationsService service) {
        this.service = service;
    }

    @GetMapping("/summary")
    @AdminPermission("data:order:read")
    public ApiResponse<AdminGroupBuySummaryResponse> summary() {
        return ApiResponse.success(service.summary());
    }

    @GetMapping("/teams")
    @AdminPermission("data:order:read")
    public ApiResponse<PageResult<AdminGroupBuyTeamResponse>> teams(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "false") boolean problemOnly,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.teams(status, problemOnly, page, pageSize));
    }

    @PostMapping("/teams/{teamId}/reconcile")
    @AdminPermission("data:order:write")
    public ApiResponse<AdminGroupBuyReconcileResponse> reconcile(
            @PathVariable Long teamId, HttpServletRequest request) {
        return ApiResponse.success(service.reconcile(teamId, request.getRemoteAddr()));
    }

    @GetMapping("/refunds/failed")
    @AdminPermission("data:order:read")
    public ApiResponse<PageResult<AdminGroupBuyFailedRefundResponse>> failedRefunds(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.failedRefunds(page, pageSize));
    }

    @PostMapping("/refunds/{refundId}/disposition")
    @AdminPermission("data:order:write")
    public ApiResponse<AdminGroupBuyRefundDispositionResponse> disposeRefund(
            @PathVariable Long refundId,
            @RequestBody AdminGroupBuyRefundDispositionRequest body,
            HttpServletRequest request) {
        return ApiResponse.success(service.disposeRefund(refundId, body, request.getRemoteAddr()));
    }
}
