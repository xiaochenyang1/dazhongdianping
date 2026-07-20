package com.tuowei.dazhongdianping.module.admin.rbac.mapper;

import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminPermissionRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminRoleRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminUserRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminRbacMapper {
    AdminUserRow selectUserByAccount(@Param("account") String account);
    AdminUserRow selectUserById(@Param("adminId") Long adminId);
    List<AdminRoleRow> selectActiveRolesByAdminId(@Param("adminId") Long adminId);
    List<AdminPermissionRow> selectActivePermissionsByAdminId(@Param("adminId") Long adminId);
    List<String> selectRegionsByAdminId(@Param("adminId") Long adminId);
    List<AdminPermissionRow> selectActivePermissions();
    List<AdminRoleRow> selectRoles();
    AdminRoleRow selectRoleById(@Param("roleId") Long roleId);
    AdminRoleRow selectRoleByCode(@Param("code") String code);
    List<AdminRoleRow> selectRolesByIds(@Param("roleIds") List<Long> roleIds);
    List<AdminRoleRow> selectRolesByAdminId(@Param("adminId") Long adminId);
    List<Long> selectPermissionIdsByRoleId(@Param("roleId") Long roleId);
    List<AdminPermissionRow> selectActivePermissionsByIds(@Param("permissionIds") List<Long> permissionIds);
    long countAdminUsersByRoleId(@Param("roleId") Long roleId);
    long countActiveSuperAdminUsers();
    void insertRole(AdminRoleRow role);
    int updateRole(AdminRoleRow role);
    int updateRoleStatus(@Param("roleId") Long roleId, @Param("status") Integer status);
    int deleteRole(@Param("roleId") Long roleId);
    void deleteRolePermissions(@Param("roleId") Long roleId);
    void insertRolePermission(@Param("roleId") Long roleId, @Param("permissionId") Long permissionId);
    long countAdminUsers();
    List<AdminUserRow> selectAdminUsers(@Param("limit") int limit, @Param("offset") int offset);
    void insertUser(AdminUserRow user);
    int updateUser(@Param("adminId") Long adminId, @Param("name") String name);
    int updateUserStatus(@Param("adminId") Long adminId, @Param("status") Integer status);
    int updateUserPassword(@Param("adminId") Long adminId, @Param("passwordHash") String passwordHash);
    void deleteUserRoles(@Param("adminId") Long adminId);
    void insertUserRole(@Param("adminId") Long adminId, @Param("roleId") Long roleId);
    void deleteAdminRegions(@Param("adminId") Long adminId);
    void insertAdminRegion(@Param("adminId") Long adminId, @Param("region") String region);
    int updateLastLoginAt(@Param("adminId") Long adminId);
    void insertAuditLog(@Param("adminId") Long adminId,
                        @Param("action") String action,
                        @Param("target") String target,
                        @Param("detail") String detail,
                        @Param("ip") String ip);
}
