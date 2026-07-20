package com.tuowei.dazhongdianping.module.community.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.community.model.request.PostSaveRequest;
import com.tuowei.dazhongdianping.module.community.model.request.PostCommentCreateRequest;
import com.tuowei.dazhongdianping.module.community.model.request.PostReportRequest;
import com.tuowei.dazhongdianping.module.community.model.response.PostResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostLikeResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostCommentResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostReportResponse;
import com.tuowei.dazhongdianping.module.community.service.CommunityService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1")
public class CommunityController {
    private final CommunityService communityService;

    public CommunityController(CommunityService communityService) {
        this.communityService = communityService;
    }

    @PostMapping("/posts")
    public ApiResponse<PostResponse> create(@Valid @RequestBody PostSaveRequest request) {
        return ApiResponse.success("帖子已提交审核", "post.created", communityService.create(request));
    }

    @PutMapping("/posts/{postId}")
    public ApiResponse<PostResponse> update(@PathVariable Long postId,
                                            @Valid @RequestBody PostSaveRequest request) {
        return ApiResponse.success("帖子已更新并重新进入审核", "post.updated", communityService.update(postId, request));
    }

    @DeleteMapping("/posts/{postId}")
    public ApiResponse<Void> delete(@PathVariable Long postId) {
        communityService.delete(postId);
        return ApiResponse.success("帖子已删除", "post.deleted", null);
    }

    @GetMapping("/posts")
    public ApiResponse<PageResult<PostResponse>> list(@RequestParam(defaultValue = "1") Integer page,
                                                      @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(communityService.publicPosts(page, pageSize));
    }

    @GetMapping("/posts/{postId}")
    public ApiResponse<PostResponse> detail(@PathVariable Long postId) {
        return ApiResponse.success(communityService.publicDetail(postId));
    }

    @GetMapping("/posts/following")
    public ApiResponse<PageResult<PostResponse>> following(@RequestParam(defaultValue = "1") Integer page,
                                                            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(communityService.followingPosts(page, pageSize));
    }

    @GetMapping("/user/posts")
    public ApiResponse<PageResult<PostResponse>> userPosts(@RequestParam(defaultValue = "1") Integer page,
                                                           @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(communityService.userPosts(page, pageSize));
    }

    @GetMapping("/user/posts/{postId}")
    public ApiResponse<PostResponse> userPost(@PathVariable Long postId) {
        return ApiResponse.success(communityService.ownedDetail(postId));
    }

    @PostMapping("/posts/{postId}/like")
    public ApiResponse<PostLikeResponse> like(@PathVariable Long postId) {
        return ApiResponse.success(communityService.toggleLike(postId));
    }

    @PostMapping("/posts/{postId}/comments")
    public ApiResponse<PostCommentResponse> comment(@PathVariable Long postId,
                                                     @Valid @RequestBody PostCommentCreateRequest request) {
        return ApiResponse.success(communityService.createComment(postId, request));
    }

    @GetMapping("/posts/{postId}/comments")
    public ApiResponse<PageResult<PostCommentResponse>> comments(@PathVariable Long postId,
                                                                  @RequestParam(defaultValue = "1") Integer page,
                                                                  @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(communityService.comments(postId, page, pageSize));
    }

    @PostMapping("/posts/{postId}/report")
    public ApiResponse<PostReportResponse> report(@PathVariable Long postId,
                                                   @Valid @RequestBody PostReportRequest request) {
        return ApiResponse.success(communityService.report(postId, request));
    }
}
