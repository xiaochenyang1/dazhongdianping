package com.tuowei.dazhongdianping.module.admin.rbac.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminPasswordResetRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminRoleSaveRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminStatusRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminUserCreateRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminUserUpdateRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminAccountResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminPermissionResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminRoleResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminRbacService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/admin/v1/rbac")
public class AdminRbacController {

    private final AdminRbacService service;

    public AdminRbacController(AdminRbacService service) {
        this.service = service;
    }

    @GetMapping("/permissions")
    @AdminPermission(value = "system:permission:read", regionScoped = false)
    public ApiResponse<List<AdminPermissionResponse>> listPermissions() {
        return ApiResponse.success(service.listPermissions());
    }

    @GetMapping("/roles")
    @AdminPermission(value = "system:role:read", regionScoped = false)
    public ApiResponse<List<AdminRoleResponse>> listRoles() {
        return ApiResponse.success(service.listRoles());
    }

    @PostMapping("/roles")
    @AdminPermission(value = "system:role:write", regionScoped = false)
    public ApiResponse<AdminRoleResponse> createRole(
            @Valid @RequestBody AdminRoleSaveRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("角色创建成功", "admin.role_created", service.createRole(request, clientIp(httpServletRequest)));
    }

    @PutMapping("/roles/{roleId}")
    @AdminPermission(value = "system:role:write", regionScoped = false)
    public ApiResponse<AdminRoleResponse> updateRole(
            @PathVariable Long roleId,
            @Valid @RequestBody AdminRoleSaveRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("角色更新成功", "admin.role_updated", service.updateRole(roleId, request, clientIp(httpServletRequest)));
    }

    @PutMapping("/roles/{roleId}/status")
    @AdminPermission(value = "system:role:write", regionScoped = false)
    public ApiResponse<AdminRoleResponse> updateRoleStatus(
            @PathVariable Long roleId,
            @Valid @RequestBody AdminStatusRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("角色状态已更新", "admin.role_status_updated",
                service.updateRoleStatus(roleId, request, clientIp(httpServletRequest)));
    }

    @DeleteMapping("/roles/{roleId}")
    @AdminPermission(value = "system:role:write", regionScoped = false)
    public ApiResponse<Void> deleteRole(@PathVariable Long roleId, HttpServletRequest httpServletRequest) {
        service.deleteRole(roleId, clientIp(httpServletRequest));
        return ApiResponse.success("角色删除成功", "admin.role_deleted", null);
    }

    @GetMapping("/admins")
    @AdminPermission(value = "system:admin:read", regionScoped = false)
    public ApiResponse<PageResult<AdminAccountResponse>> listAdmins(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize
    ) {
        return ApiResponse.success(service.listAdmins(page, pageSize));
    }

    @PostMapping("/admins")
    @AdminPermission(value = "system:admin:write", regionScoped = false)
    public ApiResponse<AdminAccountResponse> createAdmin(
            @Valid @RequestBody AdminUserCreateRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("管理员创建成功", "admin.account_created", service.createAdmin(request, clientIp(httpServletRequest)));
    }

    @PutMapping("/admins/{adminId}")
    @AdminPermission(value = "system:admin:write", regionScoped = false)
    public ApiResponse<AdminAccountResponse> updateAdmin(
            @PathVariable Long adminId,
            @Valid @RequestBody AdminUserUpdateRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("管理员更新成功", "admin.account_updated", service.updateAdmin(adminId, request, clientIp(httpServletRequest)));
    }

    @PutMapping("/admins/{adminId}/status")
    @AdminPermission(value = "system:admin:write", regionScoped = false)
    public ApiResponse<AdminAccountResponse> updateAdminStatus(
            @PathVariable Long adminId,
            @Valid @RequestBody AdminStatusRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success("管理员状态已更新", "admin.account_status_updated",
                service.updateAdminStatus(adminId, request, clientIp(httpServletRequest)));
    }

    @PutMapping("/admins/{adminId}/password")
    @AdminPermission(value = "system:admin:write", regionScoped = false)
    public ApiResponse<Void> resetAdminPassword(
            @PathVariable Long adminId,
            @Valid @RequestBody AdminPasswordResetRequest request,
            HttpServletRequest httpServletRequest
    ) {
        service.resetAdminPassword(adminId, request, clientIp(httpServletRequest));
        return ApiResponse.success("管理员密码已重置", "admin.account_password_reset", null);
    }

    @DeleteMapping("/admins/{adminId}")
    @AdminPermission(value = "system:admin:write", regionScoped = false)
    public ApiResponse<Void> deleteAdmin(@PathVariable Long adminId, HttpServletRequest httpServletRequest) {
        service.deleteAdmin(adminId, clientIp(httpServletRequest));
        return ApiResponse.success("管理员已停用", "admin.account_deleted", null);
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",", 2)[0].trim();
        }
        return request.getRemoteAddr() == null ? "" : request.getRemoteAddr();
    }
}
