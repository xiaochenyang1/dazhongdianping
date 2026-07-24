package com.tuowei.dazhongdianping.module.admin.user.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.user.model.AdminAppUserQuery;
import com.tuowei.dazhongdianping.module.admin.user.model.request.AdminAppUserStatusRequest;
import com.tuowei.dazhongdianping.module.admin.user.model.response.AdminAppUserDetailResponse;
import com.tuowei.dazhongdianping.module.admin.user.model.response.AdminAppUserResponse;
import com.tuowei.dazhongdianping.module.admin.user.service.AdminAppUserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1/users")
public class AdminAppUserController {

    private final AdminAppUserService service;

    public AdminAppUserController(AdminAppUserService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("system:user:read")
    public ApiResponse<PageResult<AdminAppUserResponse>> listUsers(@Valid AdminAppUserQuery query) {
        return ApiResponse.success(service.listUsers(query));
    }

    @GetMapping("/{userId}")
    @AdminPermission("system:user:read")
    public ApiResponse<AdminAppUserDetailResponse> getUser(@PathVariable Long userId) {
        return ApiResponse.success(service.getUserDetail(userId));
    }

    @PutMapping("/{userId}/status")
    @AdminPermission("system:user:write")
    public ApiResponse<AdminAppUserResponse> updateUserStatus(@PathVariable Long userId,
                                                              @Valid @RequestBody AdminAppUserStatusRequest request,
                                                              HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateUserStatus(userId, request, httpServletRequest.getRemoteAddr()));
    }
}
