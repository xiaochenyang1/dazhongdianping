package com.tuowei.dazhongdianping.module.admin.activity;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivityItemSaveRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivityItemStatusRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivitySaveRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivityStatusRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.response.AdminOperationActivityItemResponse;
import com.tuowei.dazhongdianping.module.admin.activity.model.response.AdminOperationActivityResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/operations/activities")
public class AdminOperationActivityController {

    private final AdminOperationActivityService service;

    public AdminOperationActivityController(AdminOperationActivityService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:activity:read")
    public ApiResponse<List<AdminOperationActivityResponse>> list(@RequestParam(required = false) Long cityId,
                                                                  @RequestParam(required = false) Integer status) {
        return ApiResponse.success(service.list(cityId, status));
    }

    @PostMapping
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityResponse> create(
            @Valid @RequestBody AdminOperationActivitySaveRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.create(request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody AdminOperationActivitySaveRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.update(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityResponse> updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody AdminOperationActivityStatusRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateStatus(id, request.status(), httpServletRequest.getRemoteAddr()));
    }

    @DeleteMapping("/{id}")
    @AdminPermission("operations:activity:write")
    public ApiResponse<Void> delete(@PathVariable Long id, HttpServletRequest httpServletRequest) {
        service.delete(id, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("活动已删除", "admin.activity_deleted", null);
    }

    @GetMapping("/{id}/items")
    @AdminPermission("operations:activity:read")
    public ApiResponse<List<AdminOperationActivityItemResponse>> listItems(@PathVariable Long id) {
        return ApiResponse.success(service.listItems(id));
    }

    @PostMapping("/{id}/items")
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityItemResponse> createItem(
            @PathVariable Long id,
            @Valid @RequestBody AdminOperationActivityItemSaveRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.createItem(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/items/{itemId}")
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityItemResponse> updateItem(
            @PathVariable Long id,
            @PathVariable Long itemId,
            @Valid @RequestBody AdminOperationActivityItemSaveRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateItem(id, itemId, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/items/{itemId}/status")
    @AdminPermission("operations:activity:write")
    public ApiResponse<AdminOperationActivityItemResponse> updateItemStatus(
            @PathVariable Long id,
            @PathVariable Long itemId,
            @Valid @RequestBody AdminOperationActivityItemStatusRequest request,
            HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateItemStatus(
                id,
                itemId,
                request.status(),
                httpServletRequest.getRemoteAddr()
        ));
    }

    @DeleteMapping("/{id}/items/{itemId}")
    @AdminPermission("operations:activity:write")
    public ApiResponse<Void> deleteItem(@PathVariable Long id,
                                        @PathVariable Long itemId,
                                        HttpServletRequest httpServletRequest) {
        service.deleteItem(id, itemId, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("活动资源项已删除", "admin.activity_item_deleted", null);
    }
}
