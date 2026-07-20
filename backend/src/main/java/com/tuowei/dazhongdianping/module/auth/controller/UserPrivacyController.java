package com.tuowei.dazhongdianping.module.auth.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyDeleteTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyExportTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyDeleteTaskResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyExportTaskResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyOverviewResponse;
import com.tuowei.dazhongdianping.module.auth.service.UserPrivacyService;
import jakarta.validation.Valid;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1/privacy")
public class UserPrivacyController {

    private final UserPrivacyService userPrivacyService;

    public UserPrivacyController(UserPrivacyService userPrivacyService) {
        this.userPrivacyService = userPrivacyService;
    }

    @GetMapping("/overview")
    public ApiResponse<PrivacyOverviewResponse> overview() {
        return ApiResponse.success(userPrivacyService.overview());
    }

    @PostMapping("/export-tasks")
    public ApiResponse<PrivacyExportTaskResponse> createExportTask(@Valid @RequestBody PrivacyExportTaskCreateRequest request) {
        return ApiResponse.success(
                "隐私导出任务已创建",
                "privacy.export_task_created",
                userPrivacyService.createExportTask(request)
        );
    }

    @GetMapping("/export-tasks")
    public ApiResponse<PageResult<PrivacyExportTaskResponse>> listExportTasks(@Valid PrivacyTaskQuery query) {
        return ApiResponse.success(userPrivacyService.listExportTasks(query));
    }

    @GetMapping("/export-tasks/{taskId}")
    public ApiResponse<PrivacyExportTaskResponse> getExportTask(@PathVariable Long taskId) {
        return ApiResponse.success(userPrivacyService.getExportTask(taskId));
    }

    @GetMapping("/export-tasks/{taskId}/download")
    public ResponseEntity<Resource> downloadExportTask(@PathVariable Long taskId) {
        return userPrivacyService.downloadExportTask(taskId);
    }

    @PostMapping("/delete-tasks")
    public ApiResponse<PrivacyDeleteTaskResponse> createDeleteTask(@Valid @RequestBody PrivacyDeleteTaskCreateRequest request) {
        return ApiResponse.success(
                "删除申请已提交",
                "privacy.delete_task_created",
                userPrivacyService.createDeleteTask(request)
        );
    }

    @PostMapping("/delete-tasks/{taskId}/cancel")
    public ApiResponse<PrivacyDeleteTaskResponse> cancelDeleteTask(@PathVariable Long taskId) {
        return ApiResponse.success(
                "删除申请已撤销",
                "privacy.delete_task_cancelled",
                userPrivacyService.cancelDeleteTask(taskId)
        );
    }
}
