package com.tuowei.dazhongdianping.module.admin.topic;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicMergeRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicRecommendationRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicStatusRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicUpdateRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.response.AdminTopicResponse;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/topics")
public class AdminTopicController {
    private final AdminTopicService service;

    public AdminTopicController(AdminTopicService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:topic:read")
    public ApiResponse<PageResult<AdminTopicResponse>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Boolean recommended,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.list(status, recommended, keyword, page, pageSize));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:topic:write")
    public ApiResponse<AdminTopicResponse> update(@PathVariable Long id,
                                                   @Valid @RequestBody TopicUpdateRequest request) {
        return ApiResponse.success(service.update(id, request));
    }

    @PutMapping("/{id}/recommendation")
    @AdminPermission("operations:topic:write")
    public ApiResponse<AdminTopicResponse> recommendation(
            @PathVariable Long id,
            @Valid @RequestBody TopicRecommendationRequest request) {
        return ApiResponse.success(service.recommendation(id, request));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:topic:write")
    public ApiResponse<AdminTopicResponse> status(@PathVariable Long id,
                                                   @Valid @RequestBody TopicStatusRequest request) {
        return ApiResponse.success(service.status(id, request));
    }

    @PostMapping("/{id}/merge")
    @AdminPermission("operations:topic:write")
    public ApiResponse<AdminTopicResponse> merge(@PathVariable Long id,
                                                  @Valid @RequestBody TopicMergeRequest request) {
        return ApiResponse.success(service.merge(id, request.targetTopicId()));
    }

    @PostMapping("/recalculate-hot")
    @AdminPermission("operations:topic:write")
    public ApiResponse<Map<String, String>> recalculateHot() {
        return ApiResponse.success(service.recalculateHot());
    }
}
