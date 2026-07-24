package com.tuowei.dazhongdianping.module.admin.trade.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.request.AdminRefundAuditRequest;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminOrderResponse;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminTradeReconcileResponse;
import com.tuowei.dazhongdianping.module.admin.trade.service.AdminTradeService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1/orders")
public class AdminTradeController {

    private final AdminTradeService service;

    public AdminTradeController(AdminTradeService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("data:order:read")
    public ApiResponse<PageResult<AdminOrderResponse>> listOrders(@Valid AdminOrderQuery query) {
        return ApiResponse.success(service.listOrders(query));
    }

    @PostMapping("/{orderId}/refund-audit")
    @AdminPermission("data:order:write")
    public ApiResponse<AdminOrderResponse> auditRefund(@PathVariable Long orderId,
                                                       @Valid @RequestBody AdminRefundAuditRequest request,
                                                       HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.auditRefund(orderId, request, httpServletRequest.getRemoteAddr()));
    }

    @PostMapping("/reconcile")
    @AdminPermission("data:order:write")
    public ApiResponse<AdminTradeReconcileResponse> reconcile(HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.reconcile(httpServletRequest.getRemoteAddr()));
    }
}
