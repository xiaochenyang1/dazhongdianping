package com.tuowei.dazhongdianping.module.admin.privacy.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.privacy.model.AdminPrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.admin.privacy.model.response.AdminPrivacyTaskResponse;
import com.tuowei.dazhongdianping.module.admin.privacy.service.AdminPrivacyService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1/privacy")
public class AdminPrivacyController {

    private final AdminPrivacyService service;

    public AdminPrivacyController(AdminPrivacyService service) {
        this.service = service;
    }

    @GetMapping("/tasks")
    @AdminPermission(value = "system:privacy_task:read", regionScoped = false)
    public ApiResponse<PageResult<AdminPrivacyTaskResponse>> listTasks(@Valid AdminPrivacyTaskQuery query) {
        return ApiResponse.success(service.listTasks(query));
    }
}
