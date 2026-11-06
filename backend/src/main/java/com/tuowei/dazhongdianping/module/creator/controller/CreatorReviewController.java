package com.tuowei.dazhongdianping.module.creator.controller;

import com.tuowei.dazhongdianping.common.api.*;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.creator.model.request.*;
import com.tuowei.dazhongdianping.module.creator.service.CreatorReviewService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
public class CreatorReviewController {
    private final CreatorReviewService service;
    public CreatorReviewController(CreatorReviewService service) { this.service = service; }

    @GetMapping("/api/c/v1/creator/evidence")
    public ApiResponse<PageResult<Map<String, Object>>> evidence(@RequestParam String type,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return ApiResponse.success(service.evidence(type, page, pageSize));
    }

    @PostMapping("/api/c/v1/creator/tasks/{id}/submit")
    public ApiResponse<Map<String, Object>> submit(@PathVariable Long id, @Valid @RequestBody CreatorSubmissionRequest body) {
        return ApiResponse.success("成果已提交", "creator.submitted", service.submit(id, body));
    }

    @GetMapping("/api/admin/v1/creator/claims")
    @AdminPermission("operations:creator:read")
    public ApiResponse<PageResult<Map<String, Object>>> claims(@RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return ApiResponse.success(service.claims(status, page, pageSize));
    }

    @PostMapping("/api/admin/v1/creator/claims/{id}/review")
    @AdminPermission("operations:creator:write")
    public ApiResponse<Map<String, Object>> review(@PathVariable Long id, @Valid @RequestBody CreatorReviewRequest body,
            HttpServletRequest request) {
        return ApiResponse.success(service.review(id, body, request.getRemoteAddr()));
    }
}
