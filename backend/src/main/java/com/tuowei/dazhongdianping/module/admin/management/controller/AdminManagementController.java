package com.tuowei.dazhongdianping.module.admin.management.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminImportBatchQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopListQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminImportShopsRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminShopSaveRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminImportBatchResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminImportResultResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminShopDetailResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminShopSummaryResponse;
import com.tuowei.dazhongdianping.module.admin.management.service.AdminManagementService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1")
public class AdminManagementController {

    private final AdminManagementService adminManagementService;

    public AdminManagementController(AdminManagementService adminManagementService) {
        this.adminManagementService = adminManagementService;
    }

    @GetMapping("/shops")
    @AdminPermission("data:shop:read")
    public ApiResponse<PageResult<AdminShopSummaryResponse>> listShops(@Valid AdminShopListQuery query) {
        return ApiResponse.success(adminManagementService.listShops(query));
    }

    @GetMapping("/shops/{shopId}")
    @AdminPermission("data:shop:read")
    public ApiResponse<AdminShopDetailResponse> getShop(@PathVariable Long shopId) {
        return ApiResponse.success(adminManagementService.getShopDetail(shopId));
    }

    @PostMapping("/shops")
    @AdminPermission("data:shop:write")
    public ApiResponse<AdminShopDetailResponse> createShop(@Valid @RequestBody AdminShopSaveRequest request) {
        return ApiResponse.success("创建成功", "admin.shop_created", adminManagementService.createShop(request));
    }

    @PutMapping("/shops/{shopId}")
    @AdminPermission("data:shop:write")
    public ApiResponse<AdminShopDetailResponse> updateShop(@PathVariable Long shopId,
                                                           @Valid @RequestBody AdminShopSaveRequest request) {
        return ApiResponse.success("更新成功", "admin.shop_updated", adminManagementService.updateShop(shopId, request));
    }

    @DeleteMapping("/shops/{shopId}")
    @AdminPermission("data:shop:write")
    public ApiResponse<Void> deleteShop(@PathVariable Long shopId) {
        adminManagementService.deleteShop(shopId);
        return ApiResponse.success("删除成功", "admin.shop_deleted", null);
    }

    @PostMapping("/import/shops")
    @AdminPermission("data:shop:import")
    public ApiResponse<AdminImportResultResponse> importShops(@Valid @RequestBody AdminImportShopsRequest request) {
        return ApiResponse.success("导入完成", "admin.import_finished", adminManagementService.importShops(request));
    }

    @GetMapping("/import/batches")
    @AdminPermission("data:import_batch:read")
    public ApiResponse<PageResult<AdminImportBatchResponse>> listImportBatches(@Valid AdminImportBatchQuery query) {
        return ApiResponse.success(adminManagementService.listImportBatches(query));
    }
}
