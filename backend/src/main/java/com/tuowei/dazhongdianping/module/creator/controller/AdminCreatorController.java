package com.tuowei.dazhongdianping.module.creator.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.creator.model.request.CreatorTaskSaveRequest;
import com.tuowei.dazhongdianping.module.creator.service.CreatorService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/creator/tasks")
public class AdminCreatorController {

    private final CreatorService service;

    public AdminCreatorController(CreatorService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:creator:read")
    public ApiResponse<PageResult<Map<String, Object>>> tasks(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return ApiResponse.success(service.adminList(page, pageSize));
    }

    @PostMapping
    @AdminPermission("operations:creator:write")
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody CreatorTaskSaveRequest request) {
        return ApiResponse.success("创作者任务已保存", "admin.creator_saved", service.create(request));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:creator:write")
    public ApiResponse<Map<String, Object>> update(
            @PathVariable Long id, @Valid @RequestBody CreatorTaskSaveRequest request) {
        return ApiResponse.success("创作者任务已保存", "admin.creator_saved", service.update(id, request));
    }
}
