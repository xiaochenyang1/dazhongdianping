package com.tuowei.dazhongdianping.module.openapi.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.openapi.model.request.OpenAppCreateRequest;
import com.tuowei.dazhongdianping.module.openapi.model.request.OpenAppStatusRequest;
import com.tuowei.dazhongdianping.module.openapi.service.AdminOpenApiService;
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
@RequestMapping("/api/admin/v1/openapi/apps")
public class AdminOpenApiController {

    private final AdminOpenApiService service;

    public AdminOpenApiController(AdminOpenApiService service) {
        this.service = service;
    }

    @PostMapping
    @AdminPermission("openapi:write")
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody OpenAppCreateRequest request) {
        return ApiResponse.success("开放应用已创建", "admin.openapi_app_created", service.create(request));
    }

    @GetMapping
    @AdminPermission("openapi:read")
    public ApiResponse<List<Map<String, Object>>> apps() {
        return ApiResponse.success(service.apps());
    }

    @PostMapping("/{id}/status")
    @AdminPermission("openapi:write")
    public ApiResponse<Map<String, Object>> updateStatus(
            @PathVariable Long id, @Valid @RequestBody OpenAppStatusRequest request) {
        return ApiResponse.success("应用状态已更新", "admin.openapi_app_updated", service.updateStatus(id, request));
    }
}
