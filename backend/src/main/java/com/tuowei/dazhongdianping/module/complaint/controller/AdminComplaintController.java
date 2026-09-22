package com.tuowei.dazhongdianping.module.complaint.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintDisposeRequest;
import com.tuowei.dazhongdianping.module.complaint.service.AdminComplaintService;
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
@RequestMapping("/api/admin/v1/complaints")
public class AdminComplaintController {

    private final AdminComplaintService service;

    public AdminComplaintController(AdminComplaintService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("audit:complaint:read")
    public ApiResponse<PageResult<Map<String, Object>>> complaints(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.complaints(status, page, pageSize));
    }

    @GetMapping("/{id}")
    @AdminPermission("audit:complaint:read")
    public ApiResponse<Map<String, Object>> detail(@PathVariable Long id) {
        return ApiResponse.success(service.detail(id));
    }

    @PostMapping("/{id}/dispose")
    @AdminPermission("audit:complaint:write")
    public ApiResponse<Map<String, Object>> dispose(
            @PathVariable Long id, @Valid @RequestBody ComplaintDisposeRequest request) {
        return ApiResponse.success("处置完成", "admin.complaint_disposed", service.dispose(id, request));
    }
}
