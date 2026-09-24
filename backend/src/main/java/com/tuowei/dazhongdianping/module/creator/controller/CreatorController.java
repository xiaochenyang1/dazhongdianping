package com.tuowei.dazhongdianping.module.creator.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.creator.service.CreatorService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/creator")
public class CreatorController {

    private final CreatorService service;

    public CreatorController(CreatorService service) {
        this.service = service;
    }

    /** 当前区域进行中的任务，附带当前用户领取状态：0 未领、1 已领、2 已完成。 */
    @GetMapping("/tasks")
    public ApiResponse<PageResult<Map<String, Object>>> tasks(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return ApiResponse.success(service.tasks(page, pageSize));
    }

    @PostMapping("/tasks/{id}/claim")
    public ApiResponse<Map<String, Object>> claim(@PathVariable Long id) {
        return ApiResponse.success("任务已领取", "creator.claimed", service.claim(id));
    }

    @PostMapping("/tasks/{id}/complete")
    public ApiResponse<Map<String, Object>> complete(@PathVariable Long id) {
        return ApiResponse.success("任务已完成", "creator.completed", service.complete(id));
    }
}
