package com.tuowei.dazhongdianping.module.guide.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.guide.service.GuideService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/guides")
public class GuideController {

    private final GuideService service;

    public GuideController(GuideService service) {
        this.service = service;
    }

    /** 已发布攻略列表（游客可读，仅当前区域）。 */
    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> guides(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return ApiResponse.success(service.published(page, pageSize));
    }

    /** 已发布攻略详情，含按 sortNo 排序的章节。 */
    @GetMapping("/{id}")
    public ApiResponse<Map<String, Object>> guide(@PathVariable Long id) {
        return ApiResponse.success(service.publishedDetail(id));
    }
}
