package com.tuowei.dazhongdianping.module.admin.audit.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditTaskQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditPassRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditRejectRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditTaskResponse;
import com.tuowei.dazhongdianping.module.admin.audit.service.AdminAuditService;
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
@RequestMapping("/api/admin/v1")
@AdminPermission(dynamic = true)
public class AdminAuditController {

    private final AdminAuditService adminAuditService;

    public AdminAuditController(AdminAuditService adminAuditService) {
        this.adminAuditService = adminAuditService;
    }

    @GetMapping("/audit/tasks")
    public ApiResponse<PageResult<AdminAuditTaskResponse>> listTasks(@Valid AdminAuditTaskQuery query) {
        return ApiResponse.success(adminAuditService.listTasks(query));
    }

    @PostMapping("/audit/tasks/{taskId}/pass")
    public ApiResponse<AdminAuditTaskResponse> passTask(@PathVariable Long taskId,
                                                        @RequestBody(required = false) AdminAuditPassRequest request,
                                                        HttpServletRequest httpServletRequest) {
        AdminAuditPassRequest payload = request == null ? new AdminAuditPassRequest() : request;
        return ApiResponse.success(
                "审核通过",
                "admin.audit_passed",
                adminAuditService.passTask(taskId, payload, httpServletRequest.getRemoteAddr())
        );
    }

    @PostMapping("/audit/tasks/{taskId}/reject")
    public ApiResponse<AdminAuditTaskResponse> rejectTask(@PathVariable Long taskId,
                                                          @Valid @RequestBody AdminAuditRejectRequest request,
                                                          HttpServletRequest httpServletRequest) {
        return ApiResponse.success(
                "审核驳回",
                "admin.audit_rejected",
                adminAuditService.rejectTask(taskId, request, httpServletRequest.getRemoteAddr())
        );
    }
}
