package com.tuowei.dazhongdianping.module.waitlist.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.waitlist.model.request.WaitlistJoinRequest;
import com.tuowei.dazhongdianping.module.waitlist.service.WaitlistService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WaitlistController {

    private final WaitlistService service;

    public WaitlistController(WaitlistService service) {
        this.service = service;
    }

    /** 取号（需登录）。 */
    @PostMapping("/api/c/v1/shops/{shopId}/waitlist")
    public ApiResponse<Map<String, Object>> join(
            @PathVariable Long shopId, @Valid @RequestBody WaitlistJoinRequest request) {
        return ApiResponse.success("取号成功", "waitlist.joined", service.join(shopId, request));
    }

    /** 我的排队（进行中）。 */
    @GetMapping("/api/c/v1/waitlist/mine")
    public ApiResponse<List<Map<String, Object>>> mine() {
        return ApiResponse.success(service.myEntries());
    }

    /** 取消排队。 */
    @PostMapping("/api/c/v1/waitlist/{id}/cancel")
    public ApiResponse<Map<String, Object>> cancel(@PathVariable Long id) {
        return ApiResponse.success("已取消排队", "waitlist.cancelled", service.cancel(id));
    }
}
