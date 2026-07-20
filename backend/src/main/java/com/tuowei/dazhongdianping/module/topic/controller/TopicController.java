package com.tuowei.dazhongdianping.module.topic.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.community.model.response.PostResponse;
import com.tuowei.dazhongdianping.module.community.service.CommunityService;
import com.tuowei.dazhongdianping.module.topic.model.response.TopicFollowResponse;
import com.tuowei.dazhongdianping.module.topic.model.response.TopicResponse;
import com.tuowei.dazhongdianping.module.topic.service.TopicService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/topics")
public class TopicController {
    private final TopicService topicService;
    private final CommunityService communityService;

    public TopicController(TopicService topicService, CommunityService communityService) {
        this.topicService = topicService;
        this.communityService = communityService;
    }

    @GetMapping
    public ApiResponse<PageResult<TopicResponse>> list(
            @RequestParam(defaultValue = "latest") String sort,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(topicService.list(sort, page, pageSize));
    }

    @GetMapping("/hot")
    public ApiResponse<PageResult<TopicResponse>> hot(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(topicService.hot(page, pageSize));
    }

    @GetMapping("/following")
    public ApiResponse<PageResult<TopicResponse>> following(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(topicService.following(page, pageSize));
    }

    @GetMapping("/{id}")
    public ApiResponse<TopicResponse> detail(@PathVariable Long id) {
        return ApiResponse.success(topicService.detail(id));
    }

    @GetMapping("/{id}/posts")
    public ApiResponse<PageResult<PostResponse>> posts(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        topicService.requireAvailable(id);
        return ApiResponse.success(communityService.topicPosts(id, page, pageSize));
    }

    @PutMapping("/{id}/follow")
    public ApiResponse<TopicFollowResponse> follow(@PathVariable Long id) {
        return ApiResponse.success(topicService.follow(id));
    }

    @DeleteMapping("/{id}/follow")
    public ApiResponse<TopicFollowResponse> unfollow(@PathVariable Long id) {
        return ApiResponse.success(topicService.unfollow(id));
    }
}
