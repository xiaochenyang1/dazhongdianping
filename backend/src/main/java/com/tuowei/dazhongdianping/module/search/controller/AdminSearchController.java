package com.tuowei.dazhongdianping.module.search.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskQuery;
import com.tuowei.dazhongdianping.module.search.model.response.AdminShopSearchSyncOverviewResponse;
import com.tuowei.dazhongdianping.module.search.model.response.AdminShopSearchSyncTaskResponse;
import com.tuowei.dazhongdianping.module.search.service.AdminShopSearchSyncService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/search")
public class AdminSearchController {

    private final AdminShopSearchSyncService adminShopSearchSyncService;

    public AdminSearchController(AdminShopSearchSyncService adminShopSearchSyncService) {
        this.adminShopSearchSyncService = adminShopSearchSyncService;
    }

    @GetMapping("/sync-tasks/overview")
    @AdminPermission("data:search_index:read")
    public ApiResponse<AdminShopSearchSyncOverviewResponse> syncOverview() {
        return ApiResponse.success(adminShopSearchSyncService.overview());
    }

    @GetMapping("/sync-tasks")
    @AdminPermission("data:search_index:read")
    public ApiResponse<PageResult<AdminShopSearchSyncTaskResponse>> listSyncTasks(
            @Valid ShopSearchSyncTaskQuery query) {
        return ApiResponse.success(adminShopSearchSyncService.list(query));
    }

    @PostMapping("/sync-tasks/{shopId}/retry")
    @AdminPermission("data:search_index:write")
    public ApiResponse<Map<String, Integer>> retrySyncTask(
            @PathVariable Long shopId,
            HttpServletRequest httpServletRequest) {
        int retried = adminShopSearchSyncService.retry(shopId, httpServletRequest.getRemoteAddr());
        return ApiResponse.success(
                "搜索同步任务已重新排队",
                "admin.search_sync_retry_success",
                Map.of("retried", retried)
        );
    }

    @PostMapping("/sync-tasks/retry-failed")
    @AdminPermission("data:search_index:write")
    public ApiResponse<Map<String, Integer>> retryFailedSyncTasks(HttpServletRequest httpServletRequest) {
        int retried = adminShopSearchSyncService.retryFailed(httpServletRequest.getRemoteAddr());
        return ApiResponse.success(
                "异常搜索同步任务已重新排队",
                "admin.search_sync_retry_failed_success",
                Map.of("retried", retried)
        );
    }

    @PostMapping("/reindex")
    @AdminPermission("data:search_index:write")
    public ApiResponse<Map<String, Integer>> rebuildShopIndex(HttpServletRequest httpServletRequest) {
        int indexed = adminShopSearchSyncService.rebuildAll(httpServletRequest.getRemoteAddr());
        return ApiResponse.success(
                "商户搜索索引已重建",
                "admin.search_reindex_success",
                Map.of("indexed", indexed)
        );
    }
}
