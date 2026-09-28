package com.tuowei.dazhongdianping.module.experiment.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.experiment.service.ExperimentService;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/flags")
public class FlagController {

    private final ExperimentService service;

    public FlagController(ExperimentService service) {
        this.service = service;
    }

    /** 当前区域开关。匿名分桶只看 flagKey，不看用户。 */
    @GetMapping
    public ApiResponse<List<Map<String, Object>>> flags() {
        return ApiResponse.success(service.flags());
    }
}
