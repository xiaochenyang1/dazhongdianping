package com.tuowei.dazhongdianping.module.admin.health;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.health.model.response.AdminSystemHealthResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/system/health")
public class AdminSystemHealthController {

    private final AdminSystemHealthService systemHealthService;

    public AdminSystemHealthController(AdminSystemHealthService systemHealthService) {
        this.systemHealthService = systemHealthService;
    }

    @GetMapping
    @AdminPermission(value = "system:health:read", regionScoped = false)
    public ApiResponse<AdminSystemHealthResponse> inspect() {
        return ApiResponse.success(systemHealthService.inspect());
    }
}
