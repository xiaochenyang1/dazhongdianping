package com.tuowei.dazhongdianping.module.admin.sensitiveword;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.sensitiveword.model.request.AdminSensitiveWordSaveRequest;
import com.tuowei.dazhongdianping.module.admin.sensitiveword.model.request.AdminSensitiveWordStatusRequest;
import com.tuowei.dazhongdianping.module.admin.sensitiveword.model.response.AdminSensitiveWordResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/operations/sensitive-words")
public class AdminSensitiveWordController {

    private final AdminSensitiveWordService service;

    public AdminSensitiveWordController(AdminSensitiveWordService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:sensitive_word:read")
    public ApiResponse<List<AdminSensitiveWordResponse>> list() {
        return ApiResponse.success(service.list());
    }

    @PostMapping
    @AdminPermission("operations:sensitive_word:write")
    public ApiResponse<AdminSensitiveWordResponse> create(
            @Valid @RequestBody AdminSensitiveWordSaveRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.create(request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:sensitive_word:write")
    public ApiResponse<AdminSensitiveWordResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody AdminSensitiveWordSaveRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.update(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:sensitive_word:write")
    public ApiResponse<AdminSensitiveWordResponse> updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody AdminSensitiveWordStatusRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.updateStatus(id, request.enabled(), httpServletRequest.getRemoteAddr()));
    }

    @DeleteMapping("/{id}")
    @AdminPermission("operations:sensitive_word:write")
    public ApiResponse<Void> delete(@PathVariable Long id, HttpServletRequest httpServletRequest) {
        service.delete(id, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("敏感词已删除", "admin.sensitive_word_deleted", null);
    }
}
