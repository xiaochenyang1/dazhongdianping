package com.tuowei.dazhongdianping.module.circle.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleMemberResponse;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleMembershipResponse;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleResponse;
import com.tuowei.dazhongdianping.module.circle.service.CircleService;
import com.tuowei.dazhongdianping.module.community.model.response.PostResponse;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/groups")
public class CircleController {
    private final CircleService service;
    public CircleController(CircleService service) { this.service = service; }
    @GetMapping public ApiResponse<PageResult<CircleResponse>> list(@RequestParam(required = false) Boolean joined,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.list(joined, page, pageSize));
    }
    @GetMapping("/{id}") public ApiResponse<CircleResponse> detail(@PathVariable Long id) { return ApiResponse.success(service.detail(id)); }
    @GetMapping("/{id}/members") public ApiResponse<PageResult<CircleMemberResponse>> members(@PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.members(id, page, pageSize));
    }
    @GetMapping("/{id}/posts") public ApiResponse<PageResult<PostResponse>> posts(@PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.posts(id, page, pageSize));
    }
    @PutMapping("/{id}/membership") public ApiResponse<CircleMembershipResponse> join(@PathVariable Long id) { return ApiResponse.success(service.join(id)); }
    @DeleteMapping("/{id}/membership") public ApiResponse<CircleMembershipResponse> leave(@PathVariable Long id) { return ApiResponse.success(service.leave(id)); }
}
