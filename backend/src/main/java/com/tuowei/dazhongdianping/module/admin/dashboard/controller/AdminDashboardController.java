package com.tuowei.dazhongdianping.module.admin.dashboard.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.dashboard.model.response.AdminDashboardResponse;
import com.tuowei.dazhongdianping.module.admin.dashboard.service.AdminDashboardService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1")
public class AdminDashboardController {

    private final AdminDashboardService service;

    public AdminDashboardController(AdminDashboardService service) {
        this.service = service;
    }

    @GetMapping("/dashboard/overview")
    @AdminPermission("dashboard:read")
    public ApiResponse<AdminDashboardResponse> overview() {
        return ApiResponse.success(service.overview());
    }
}
