package com.tuowei.dazhongdianping.module.points.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.points.model.request.PointsExchangeResolveRequest;
import com.tuowei.dazhongdianping.module.points.model.response.AdminPointsExchangeResponse;
import com.tuowei.dazhongdianping.module.points.service.AdminPointsExchangeService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/points/exchanges")
public class AdminPointsExchangeController {

    private final AdminPointsExchangeService service;

    public AdminPointsExchangeController(AdminPointsExchangeService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:points:read")
    public ApiResponse<PageResult<AdminPointsExchangeResponse>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.list(status, keyword, page, pageSize));
    }

    @PostMapping("/{id}/fulfill")
    @AdminPermission("operations:points:write")
    public ApiResponse<AdminPointsExchangeResponse> fulfill(
            @PathVariable Long id,
            @Valid @RequestBody(required = false) PointsExchangeResolveRequest request,
            HttpServletRequest httpServletRequest) {
        PointsExchangeResolveRequest body = request == null ? new PointsExchangeResolveRequest() : request;
        return ApiResponse.success("兑换已发放", "admin.points_exchange_fulfilled",
                service.fulfill(id, body.getRedeemCode(), body.getRemark(), httpServletRequest.getRemoteAddr()));
    }

    @PostMapping("/{id}/cancel")
    @AdminPermission("operations:points:write")
    public ApiResponse<AdminPointsExchangeResponse> cancel(
            @PathVariable Long id,
            @Valid @RequestBody(required = false) PointsExchangeResolveRequest request,
            HttpServletRequest httpServletRequest) {
        PointsExchangeResolveRequest body = request == null ? new PointsExchangeResolveRequest() : request;
        return ApiResponse.success("兑换已取消，积分已退回", "admin.points_exchange_cancelled",
                service.cancel(id, body.getRemark(), httpServletRequest.getRemoteAddr()));
    }
}
