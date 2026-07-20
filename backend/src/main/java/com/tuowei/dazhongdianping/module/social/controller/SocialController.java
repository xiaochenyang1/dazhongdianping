package com.tuowei.dazhongdianping.module.social.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.social.model.response.FollowStatusResponse;
import com.tuowei.dazhongdianping.module.social.model.response.SocialUserResponse;
import com.tuowei.dazhongdianping.module.social.service.SocialService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1")
public class SocialController {
    private final SocialService service;
    public SocialController(SocialService service) { this.service = service; }
    @PutMapping("/follow/{userId}")
    public ApiResponse<FollowStatusResponse> follow(@PathVariable Long userId) { return ApiResponse.success(service.follow(userId)); }
    @DeleteMapping("/follow/{userId}")
    public ApiResponse<FollowStatusResponse> unfollow(@PathVariable Long userId) { return ApiResponse.success(service.unfollow(userId)); }
    @GetMapping("/user/{userId}/followers")
    public ApiResponse<PageResult<SocialUserResponse>> followers(@PathVariable Long userId,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.followers(userId, page, pageSize));
    }
    @GetMapping("/user/{userId}/following")
    public ApiResponse<PageResult<SocialUserResponse>> following(@PathVariable Long userId,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.following(userId, page, pageSize));
    }
}
