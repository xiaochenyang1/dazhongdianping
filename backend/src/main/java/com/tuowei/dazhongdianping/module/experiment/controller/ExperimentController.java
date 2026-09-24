package com.tuowei.dazhongdianping.module.experiment.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.experiment.model.request.ExperimentAssignRequest;
import com.tuowei.dazhongdianping.module.experiment.service.ExperimentService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/experiments")
public class ExperimentController {

    private final ExperimentService service;

    public ExperimentController(ExperimentService service) {
        this.service = service;
    }

    /** 分配 A/B。已分配过则原样返回，不改分组。 */
    @PostMapping("/{id}/assign")
    public ApiResponse<Map<String, Object>> assign(
            @PathVariable Long id, @Valid @RequestBody ExperimentAssignRequest request) {
        return ApiResponse.success("已分配实验分组", "experiment.assigned", service.assign(id, request.variant()));
    }
}
