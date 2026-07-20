package com.tuowei.dazhongdianping.module.admin.rbac.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.admin.rbac.mapper.AdminRbacMapper;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminPermissionRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminRoleRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminUserRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminPasswordResetRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminRoleSaveRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminStatusRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminUserCreateRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.request.AdminUserUpdateRequest;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminAccountResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminPermissionResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.model.response.AdminRoleResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminRbacService {

    private static final String SUPER_ADMIN_ROLE = "super_admin";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminRbacMapper mapper;
    private final AdminAuditLogService auditLogService;
    private final ObjectMapper objectMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AdminRbacService(
            AdminRbacMapper mapper,
            AdminAuditLogService auditLogService,
            ObjectMapper objectMapper
    ) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    public List<AdminPermissionResponse> listPermissions() {
        return mapper.selectActivePermissions().stream()
                .map(permission -> new AdminPermissionResponse(
                        permission.getId(),
                        permission.getCode(),
                        permission.getName(),
                        permission.getCategory(),
                        permission.getPermissionType()
                ))
                .toList();
    }

    public List<AdminRoleResponse> listRoles() {
        return mapper.selectRoles().stream().map(this::toRoleResponse).toList();
    }

    @Transactional
    public AdminRoleResponse createRole(AdminRoleSaveRequest request, String requestIp) {
        String code = normalizeRoleCode(request.code());
        if (mapper.selectRoleByCode(code) != null) {
            throw new ConflictException("角色编码已存在");
        }
        List<Long> permissionIds = validatePermissionIds(request.permissionIds());

        AdminRoleRow role = new AdminRoleRow();
        role.setCode(code);
        role.setName(request.name().trim());
        role.setDescription(normalizeDescription(request.description()));
        role.setStatus(1);
        role.setBuiltIn(false);
        mapper.insertRole(role);
        replaceRolePermissions(role.getId(), permissionIds);
        record("admin.role_create", "role:" + role.getId(), Map.of("permissionIds", permissionIds), requestIp);
        return toRoleResponse(requireRole(role.getId()));
    }

    @Transactional
    public AdminRoleResponse updateRole(Long roleId, AdminRoleSaveRequest request, String requestIp) {
        AdminRoleRow existing = requireRole(roleId);
        String code = normalizeRoleCode(request.code());
        AdminRoleRow sameCode = mapper.selectRoleByCode(code);
        if (sameCode != null && !roleId.equals(sameCode.getId())) {
            throw new ConflictException("角色编码已存在");
        }
        if (Boolean.TRUE.equals(existing.getBuiltIn()) && !existing.getCode().equals(code)) {
            throw new ConflictException("内置角色不能修改角色编码");
        }
        List<Long> permissionIds = validatePermissionIds(request.permissionIds());
        List<Long> currentPermissionIds = mapper.selectPermissionIdsByRoleId(roleId);
        if (SUPER_ADMIN_ROLE.equals(existing.getCode())
                && !new LinkedHashSet<>(currentPermissionIds).equals(new LinkedHashSet<>(permissionIds))) {
            throw new ConflictException("超级管理员角色不能修改权限集合");
        }

        existing.setCode(code);
        existing.setName(request.name().trim());
        existing.setDescription(normalizeDescription(request.description()));
        mapper.updateRole(existing);
        if (!SUPER_ADMIN_ROLE.equals(existing.getCode())) {
            replaceRolePermissions(roleId, permissionIds);
        }
        record("admin.role_update", "role:" + roleId, Map.of("permissionIds", permissionIds), requestIp);
        return toRoleResponse(requireRole(roleId));
    }

    @Transactional
    public AdminRoleResponse updateRoleStatus(Long roleId, AdminStatusRequest request, String requestIp) {
        AdminRoleRow role = requireRole(roleId);
        int status = validateStatus(request.status());
        if (SUPER_ADMIN_ROLE.equals(role.getCode())) {
            throw new ConflictException("超级管理员角色不能停用");
        }
        mapper.updateRoleStatus(roleId, status);
        record("admin.role_status", "role:" + roleId, Map.of("status", status), requestIp);
        return toRoleResponse(requireRole(roleId));
    }

    @Transactional
    public void deleteRole(Long roleId, String requestIp) {
        AdminRoleRow role = requireRole(roleId);
        if (Boolean.TRUE.equals(role.getBuiltIn())) {
            throw new ConflictException("内置角色不能删除");
        }
        if (mapper.countAdminUsersByRoleId(roleId) > 0) {
            throw new ConflictException("角色仍被管理员引用，不能删除");
        }
        mapper.deleteRolePermissions(roleId);
        mapper.deleteRole(roleId);
        record("admin.role_delete", "role:" + roleId, Map.of(), requestIp);
    }

    public PageResult<AdminAccountResponse> listAdmins(Integer page, Integer pageSize) {
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        long total = mapper.countAdminUsers();
        List<AdminAccountResponse> list = mapper.selectAdminUsers(
                        normalizedPageSize,
                        (normalizedPage - 1) * normalizedPageSize
                )
                .stream()
                .map(this::toAdminAccountResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                normalizedPage,
                normalizedPageSize,
                (normalizedPage - 1) * normalizedPageSize + list.size() < total
        );
    }

    @Transactional
    public AdminAccountResponse createAdmin(AdminUserCreateRequest request, String requestIp) {
        String account = normalizeAccount(request.account());
        if (mapper.selectUserByAccount(account) != null) {
            throw new ConflictException("管理员账号已存在");
        }
        List<Long> roleIds = validateActiveRoleIds(request.roleIds());
        List<String> regions = normalizeRegions(request.regions());

        AdminUserRow user = new AdminUserRow();
        user.setAccount(account);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setName(request.name().trim());
        user.setStatus(1);
        mapper.insertUser(user);
        replaceUserRoles(user.getId(), roleIds);
        replaceAdminRegions(user.getId(), regions);
        record("admin.account_create", "admin:" + user.getId(),
                Map.of("roleIds", roleIds, "regions", regions), requestIp);
        return toAdminAccountResponse(requireUser(user.getId()));
    }

    @Transactional
    public AdminAccountResponse updateAdmin(Long adminId, AdminUserUpdateRequest request, String requestIp) {
        AdminUserRow user = requireUser(adminId);
        List<Long> roleIds = validateActiveRoleIds(request.roleIds());
        List<String> regions = normalizeRegions(request.regions());
        if (isActiveSuperAdmin(user) && !hasSuperAdminRole(roleIds) && mapper.countActiveSuperAdminUsers() <= 1) {
            throw new ConflictException("不能移除最后一个有效超级管理员");
        }
        mapper.updateUser(adminId, request.name().trim());
        replaceUserRoles(adminId, roleIds);
        replaceAdminRegions(adminId, regions);
        record("admin.account_update", "admin:" + adminId,
                Map.of("roleIds", roleIds, "regions", regions), requestIp);
        return toAdminAccountResponse(requireUser(adminId));
    }

    @Transactional
    public AdminAccountResponse updateAdminStatus(Long adminId, AdminStatusRequest request, String requestIp) {
        AdminUserRow user = requireUser(adminId);
        int status = validateStatus(request.status());
        ensureCanDisableAdmin(user, status);
        mapper.updateUserStatus(adminId, status);
        record("admin.account_status", "admin:" + adminId, Map.of("status", status), requestIp);
        return toAdminAccountResponse(requireUser(adminId));
    }

    @Transactional
    public void resetAdminPassword(Long adminId, AdminPasswordResetRequest request, String requestIp) {
        requireUser(adminId);
        mapper.updateUserPassword(adminId, passwordEncoder.encode(request.password()));
        record("admin.account_password_reset", "admin:" + adminId, Map.of(), requestIp);
    }

    @Transactional
    public void deleteAdmin(Long adminId, String requestIp) {
        AdminUserRow user = requireUser(adminId);
        ensureCanDisableAdmin(user, 2);
        mapper.updateUserStatus(adminId, 2);
        record("admin.account_delete", "admin:" + adminId, Map.of(), requestIp);
    }

    private void ensureCanDisableAdmin(AdminUserRow user, int targetStatus) {
        if (targetStatus != 2) {
            return;
        }
        if (user.getId().equals(currentAdmin().adminId())) {
            throw new ConflictException("不能停用当前登录管理员");
        }
        if (isActiveSuperAdmin(user) && mapper.countActiveSuperAdminUsers() <= 1) {
            throw new ConflictException("不能停用最后一个有效超级管理员");
        }
    }

    private AdminRoleRow requireRole(Long roleId) {
        AdminRoleRow role = mapper.selectRoleById(roleId);
        if (role == null) {
            throw new NotFoundException("角色不存在");
        }
        return role;
    }

    private AdminUserRow requireUser(Long adminId) {
        AdminUserRow user = mapper.selectUserById(adminId);
        if (user == null) {
            throw new NotFoundException("管理员不存在");
        }
        return user;
    }

    private List<Long> validatePermissionIds(List<Long> requestedPermissionIds) {
        List<Long> permissionIds = distinctIds(requestedPermissionIds, "权限不能为空");
        List<AdminPermissionRow> permissions = mapper.selectActivePermissionsByIds(permissionIds);
        if (permissions.size() != permissionIds.size()) {
            throw new IllegalArgumentException("权限不存在或已停用");
        }
        return permissionIds;
    }

    private List<Long> validateActiveRoleIds(List<Long> requestedRoleIds) {
        List<Long> roleIds = distinctIds(requestedRoleIds, "角色不能为空");
        List<AdminRoleRow> roles = mapper.selectRolesByIds(roleIds);
        if (roles.size() != roleIds.size() || roles.stream().anyMatch(role -> !Integer.valueOf(1).equals(role.getStatus()))) {
            throw new IllegalArgumentException("角色不存在或已停用");
        }
        return roleIds;
    }

    private List<Long> distinctIds(List<Long> values, String message) {
        if (values == null) {
            throw new IllegalArgumentException(message);
        }
        List<Long> ids = values.stream().filter(value -> value != null && value > 0)
                .collect(java.util.stream.Collectors.toCollection(LinkedHashSet::new))
                .stream()
                .toList();
        if (ids.isEmpty()) {
            throw new IllegalArgumentException(message);
        }
        return ids;
    }

    private List<String> normalizeRegions(List<String> requestedRegions) {
        if (requestedRegions == null) {
            throw new IllegalArgumentException("至少选择一个区域");
        }
        Set<String> values = new LinkedHashSet<>();
        for (String rawRegion : requestedRegions) {
            try {
                values.add(Region.valueOf(rawRegion.trim().toUpperCase(Locale.ROOT)).name());
            } catch (RuntimeException exception) {
                throw new IllegalArgumentException("区域不合法");
            }
        }
        if (values.isEmpty()) {
            throw new IllegalArgumentException("至少选择一个区域");
        }
        return values.stream().sorted().toList();
    }

    private void replaceRolePermissions(Long roleId, List<Long> permissionIds) {
        mapper.deleteRolePermissions(roleId);
        permissionIds.forEach(permissionId -> mapper.insertRolePermission(roleId, permissionId));
    }

    private void replaceUserRoles(Long adminId, List<Long> roleIds) {
        mapper.deleteUserRoles(adminId);
        roleIds.forEach(roleId -> mapper.insertUserRole(adminId, roleId));
    }

    private void replaceAdminRegions(Long adminId, List<String> regions) {
        mapper.deleteAdminRegions(adminId);
        regions.forEach(region -> mapper.insertAdminRegion(adminId, region));
    }

    private boolean isActiveSuperAdmin(AdminUserRow user) {
        return Integer.valueOf(1).equals(user.getStatus())
                && mapper.selectRolesByAdminId(user.getId()).stream()
                .anyMatch(role -> SUPER_ADMIN_ROLE.equals(role.getCode()) && Integer.valueOf(1).equals(role.getStatus()));
    }

    private boolean hasSuperAdminRole(List<Long> roleIds) {
        return mapper.selectRolesByIds(roleIds).stream()
                .anyMatch(role -> SUPER_ADMIN_ROLE.equals(role.getCode()));
    }

    private AdminRoleResponse toRoleResponse(AdminRoleRow role) {
        return new AdminRoleResponse(
                role.getId(),
                role.getCode(),
                role.getName(),
                role.getDescription(),
                role.getStatus(),
                role.getBuiltIn(),
                mapper.selectPermissionIdsByRoleId(role.getId()),
                mapper.countAdminUsersByRoleId(role.getId())
        );
    }

    private AdminAccountResponse toAdminAccountResponse(AdminUserRow user) {
        List<AdminRoleRow> roles = mapper.selectRolesByAdminId(user.getId());
        return new AdminAccountResponse(
                user.getId(),
                user.getAccount(),
                user.getName(),
                user.getStatus(),
                roles.stream().map(AdminRoleRow::getId).toList(),
                roles.stream().map(AdminRoleRow::getName).toList(),
                mapper.selectRegionsByAdminId(user.getId()),
                formatDateTime(user.getLastLoginAt())
        );
    }

    private int validateStatus(Integer status) {
        if (status == null || (status != 1 && status != 2)) {
            throw new IllegalArgumentException("status 仅支持 1 或 2");
        }
        return status;
    }

    private String normalizeRoleCode(String value) {
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeAccount(String value) {
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeDescription(String value) {
        return value == null ? "" : value.trim();
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }

    private void record(String action, String target, Map<String, ?> detail, String requestIp) {
        auditLogService.record(currentAdmin().adminId(), action, target, toJson(detail), requestIp);
    }

    private String toJson(Map<String, ?> detail) {
        try {
            return objectMapper.writeValueAsString(detail);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("管理员审计日志序列化失败", exception);
        }
    }
}
