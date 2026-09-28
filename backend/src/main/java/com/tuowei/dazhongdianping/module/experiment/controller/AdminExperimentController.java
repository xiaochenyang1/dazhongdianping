package com.tuowei.dazhongdianping.module.experiment.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.experiment.model.request.ExperimentSaveRequest;
import com.tuowei.dazhongdianping.module.experiment.model.request.FlagSaveRequest;
import com.tuowei.dazhongdianping.module.experiment.service.ExperimentService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1")
public class AdminExperimentController {

    private final ExperimentService service;

    public AdminExperimentController(ExperimentService service) {
        this.service = service;
    }

    @GetMapping("/flags")
    @AdminPermission("operations:experiment:read")
    public ApiResponse<List<Map<String, Object>>> flags() {
        return ApiResponse.success(service.adminFlags());
    }

    @PostMapping("/flags")
    @AdminPermission("operations:experiment:write")
    public ApiResponse<Map<String, Object>> createFlag(@Valid @RequestBody FlagSaveRequest request) {
        return ApiResponse.success("开关已保存", "admin.flag_saved", service.createFlag(request));
    }

    @PutMapping("/flags/{id}")
    @AdminPermission("operations:experiment:write")
    public ApiResponse<Map<String, Object>> updateFlag(
            @PathVariable Long id, @Valid @RequestBody FlagSaveRequest request) {
        return ApiResponse.success("开关已保存", "admin.flag_saved", service.updateFlag(id, request));
    }

    @GetMapping("/experiments")
    @AdminPermission("operations:experiment:read")
    public ApiResponse<List<Map<String, Object>>> experiments() {
        return ApiResponse.success(service.adminExperiments());
    }

    @PostMapping("/experiments")
    @AdminPermission("operations:experiment:write")
    public ApiResponse<Map<String, Object>> createExperiment(@Valid @RequestBody ExperimentSaveRequest request) {
        return ApiResponse.success("实验已保存", "admin.experiment_saved", service.createExperiment(request));
    }
}
