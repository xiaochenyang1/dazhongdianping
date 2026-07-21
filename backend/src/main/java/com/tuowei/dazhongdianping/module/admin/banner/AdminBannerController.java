package com.tuowei.dazhongdianping.module.admin.banner;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.banner.model.request.AdminBannerSaveRequest;
import com.tuowei.dazhongdianping.module.admin.banner.model.request.AdminBannerStatusRequest;
import com.tuowei.dazhongdianping.module.admin.banner.model.response.AdminBannerResponse;
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
@RequestMapping("/api/admin/v1/banners")
public class AdminBannerController {

    private final AdminBannerService service;

    public AdminBannerController(AdminBannerService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:banner:read")
    public ApiResponse<List<AdminBannerResponse>> list(@RequestParam(required = false) Long cityId) {
        return ApiResponse.success(service.list(cityId));
    }

    @PostMapping
    @AdminPermission("operations:banner:write")
    public ApiResponse<AdminBannerResponse> create(@Valid @RequestBody AdminBannerSaveRequest request,
                                                   HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.create(request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:banner:write")
    public ApiResponse<AdminBannerResponse> update(@PathVariable Long id,
                                                   @Valid @RequestBody AdminBannerSaveRequest request,
                                                   HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.update(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:banner:write")
    public ApiResponse<AdminBannerResponse> updateStatus(@PathVariable Long id,
                                                         @Valid @RequestBody AdminBannerStatusRequest request,
                                                         HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateStatus(id, request.enabled(), httpServletRequest.getRemoteAddr()));
    }

    @DeleteMapping("/{id}")
    @AdminPermission("operations:banner:write")
    public ApiResponse<Void> delete(@PathVariable Long id, HttpServletRequest httpServletRequest) {
        service.delete(id, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("Banner 已删除", "admin.banner_deleted", null);
    }
}
