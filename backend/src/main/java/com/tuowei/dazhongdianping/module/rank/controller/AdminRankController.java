package com.tuowei.dazhongdianping.module.rank.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.rank.model.request.RankConfigSaveRequest;
import com.tuowei.dazhongdianping.module.rank.model.response.RankConfigResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankPublishResponse;
import com.tuowei.dazhongdianping.module.rank.service.AdminRankService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/ranks/config")
public class AdminRankController {
    private final AdminRankService adminRankService;
    public AdminRankController(AdminRankService adminRankService) { this.adminRankService = adminRankService; }
    @GetMapping @AdminPermission("operations:rank:read") public ApiResponse<List<RankConfigResponse>> list() { return ApiResponse.success(adminRankService.list()); }
    @PostMapping @AdminPermission("operations:rank:write") public ApiResponse<RankConfigResponse> create(@Valid @RequestBody RankConfigSaveRequest request) { return ApiResponse.success(adminRankService.createDraft(request)); }
    @PutMapping("/{configId}") @AdminPermission("operations:rank:write") public ApiResponse<RankConfigResponse> update(@PathVariable Long configId, @Valid @RequestBody RankConfigSaveRequest request) { return ApiResponse.success(adminRankService.updateDraft(configId, request)); }
    @PostMapping("/{configId}/publish") @AdminPermission("operations:rank:write") public ApiResponse<RankPublishResponse> publish(@PathVariable Long configId) { return ApiResponse.success(adminRankService.publish(configId)); }
    @PostMapping("/{configId}/rollback") @AdminPermission("operations:rank:write") public ApiResponse<RankPublishResponse> rollback(@PathVariable Long configId) { return ApiResponse.success(adminRankService.rollback(configId)); }
}
