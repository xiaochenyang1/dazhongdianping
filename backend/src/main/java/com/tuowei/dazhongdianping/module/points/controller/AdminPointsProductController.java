package com.tuowei.dazhongdianping.module.points.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.points.model.request.PointsProductSaveRequest;
import com.tuowei.dazhongdianping.module.points.model.request.PointsProductStatusRequest;
import com.tuowei.dazhongdianping.module.points.model.response.PointsProductResponse;
import com.tuowei.dazhongdianping.module.points.service.AdminPointsProductService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
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
@RequestMapping("/api/admin/v1/points/products")
public class AdminPointsProductController {

    private final AdminPointsProductService service;

    public AdminPointsProductController(AdminPointsProductService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:points:read")
    public ApiResponse<PageResult<PointsProductResponse>> list(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.list(page, pageSize));
    }

    @PostMapping
    @AdminPermission("operations:points:write")
    public ApiResponse<PointsProductResponse> create(@Valid @RequestBody PointsProductSaveRequest request,
                                                     HttpServletRequest httpServletRequest) {
        return ApiResponse.success("积分商品已创建", "admin.points_product_created",
                service.create(request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:points:write")
    public ApiResponse<PointsProductResponse> update(@PathVariable Long id,
                                                     @Valid @RequestBody PointsProductSaveRequest request,
                                                     HttpServletRequest httpServletRequest) {
        return ApiResponse.success("积分商品已更新", "admin.points_product_updated",
                service.update(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:points:write")
    public ApiResponse<PointsProductResponse> updateStatus(@PathVariable Long id,
                                                           @Valid @RequestBody PointsProductStatusRequest request,
                                                           HttpServletRequest httpServletRequest) {
        return ApiResponse.success("状态已更新", "admin.points_product_status_updated",
                service.updateStatus(id, request.getStatus(), httpServletRequest.getRemoteAddr()));
    }

    @DeleteMapping("/{id}")
    @AdminPermission("operations:points:write")
    public ApiResponse<Void> delete(@PathVariable Long id, HttpServletRequest httpServletRequest) {
        service.delete(id, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("积分商品已删除", "admin.points_product_deleted", null);
    }
}
