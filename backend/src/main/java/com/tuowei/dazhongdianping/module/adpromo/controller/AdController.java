package com.tuowei.dazhongdianping.module.adpromo.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.adpromo.service.AdService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/ads")
public class AdController {

    private final AdService service;

    public AdController(AdService service) {
        this.service = service;
    }

    /** 固定广告位召回（匿名可用）。slotType 1=搜索 2=首页/列表。 */
    @GetMapping
    public ApiResponse<List<Map<String, Object>>> serve(
            @RequestParam(required = false) Integer slotType,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer limit) {
        return ApiResponse.success(service.serve(slotType, keyword, limit));
    }

    /**
     * 广告点击上报并计费。匿名访客按 getRemoteAddr 去重（不信任客户端可伪造的 X-Forwarded-For；
     * 反向代理部署需由容器 RemoteIpValve / forward-headers-strategy 在可信代理边界还原真实 IP）。
     */
    @PostMapping("/{id}/click")
    public ApiResponse<Map<String, Object>> click(@PathVariable Long id, HttpServletRequest request) {
        return ApiResponse.success(service.click(id, request.getRemoteAddr()));
    }
}
