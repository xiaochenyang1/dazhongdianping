package com.tuowei.dazhongdianping.module.guide.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.guide.model.request.GuideSaveRequest;
import com.tuowei.dazhongdianping.module.guide.model.request.GuideStatusRequest;
import com.tuowei.dazhongdianping.module.guide.service.GuideService;
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
@RequestMapping("/api/admin/v1/guides")
public class AdminGuideController {

    private final GuideService service;

    public AdminGuideController(GuideService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:guide:read")
    public ApiResponse<PageResult<Map<String, Object>>> guides(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return ApiResponse.success(service.adminList(page, pageSize));
    }

    @PostMapping
    @AdminPermission("operations:guide:write")
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody GuideSaveRequest request) {
        return ApiResponse.success("攻略已保存", "admin.guide_saved", service.create(request));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:guide:write")
    public ApiResponse<Map<String, Object>> update(
            @PathVariable Long id, @Valid @RequestBody GuideSaveRequest request) {
        return ApiResponse.success("攻略已保存", "admin.guide_saved", service.update(id, request));
    }

    @PostMapping("/{id}/status")
    @AdminPermission("operations:guide:write")
    public ApiResponse<Map<String, Object>> status(
            @PathVariable Long id, @Valid @RequestBody GuideStatusRequest request) {
        return ApiResponse.success("攻略已保存", "admin.guide_saved", service.updateStatus(id, request.status()));
    }
}
