# 管理端数据库 RBAC 基础 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将配置化单管理员升级为数据库管理员、角色权限、区域范围、菜单过滤和管理员/角色管理页面。

**Architecture:** 保留现有 opaque token 和 MVC interceptor，但 token 只缓存 `adminId + expiresAt`，每次请求从数据库重建权限与区域 session。固定业务接口使用 `@AdminPermission`，统一审核接口使用 `dynamic=true` 后按 `biz_type` 二次鉴权；前端菜单与路由复用同一权限码。

**Tech Stack:** Java 17、Spring Boot MVC、MyBatis、H2/MySQL、BCrypt、Vue 3、TypeScript、Vue Router、Vitest/jsdom

---

> 当前目录无 `.git`，不能创建 worktree、commit 或 push。每个任务以测试通过和计划勾选作为检查点；若用户之后提供 Git 仓库，只做本地 commit，不 push。

### Task 1: 建立 RBAC 表和可信种子

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/rbac/AdminRbacSeedTest.java`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `backend/src/main/resources/data.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `sql/mysql/02_seed_data.sql`

- [x] **Step 1: 编写失败的数据库种子测试**

使用 `JdbcTemplate` 断言：

```java
@Test
void shouldSeedDatabaseAdminRolesPermissionsAndRegions() {
    assertEquals("系统管理员", jdbc.queryForObject(
            "SELECT name FROM admin_user WHERE id=1 AND account='admin' AND status=1", String.class));
    String hash = jdbc.queryForObject(
            "SELECT password_hash FROM admin_user WHERE id=1", String.class);
    assertTrue(new BCryptPasswordEncoder().matches("admin123456", hash));
    assertEquals(List.of("CN", "EU"), jdbc.queryForList(
            "SELECT region FROM admin_region_scope WHERE admin_id=1 ORDER BY region", String.class));
    assertEquals(5, jdbc.queryForObject("SELECT COUNT(1) FROM admin_role", Integer.class));
    assertEquals(1, jdbc.queryForObject(
            "SELECT COUNT(1) FROM admin_user_role aur JOIN admin_role ar ON ar.id=aur.role_id "
                    + "WHERE aur.admin_id=1 AND ar.code='super_admin'", Integer.class));
    assertEquals(0, jdbc.queryForObject(
            "SELECT COUNT(1) FROM admin_permission ap "
                    + "LEFT JOIN admin_role_permission arp ON arp.permission_id=ap.id "
                    + "AND arp.role_id=(SELECT id FROM admin_role WHERE code='super_admin') "
                    + "WHERE ap.status=1 AND arp.permission_id IS NULL", Integer.class));
}
```

- [x] **Step 2: 运行测试确认 RED**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminRbacSeedTest test`

Expected: FAIL，提示 `admin_user` 或关联表不存在。

- [x] **Step 3: 同步新增 H2/MySQL 表与种子**

新增：

```sql
admin_user(id, account, password_hash, name, status, last_login_at, created_at, updated_at)
admin_role(id, code, name, description, status, built_in, created_at, updated_at)
admin_permission(id, code, name, category, type, status)
admin_user_role(admin_id, role_id)
admin_role_permission(role_id, permission_id)
admin_region_scope(admin_id, region)
```

种子写入 `admin`、五个内置角色、规格中的全部权限、超级管理员全部权限和 `CN/EU` 区域。规格里写作 `read/write` 的权限必须展开为两条独立权限码，例如 `audit:review:read` 与 `audit:review:write`。该段“暂时保留旧配置账号”仅描述 Task 1 的历史过渡；Task 2 已完成数据库登录切换并删除明文配置。

- [x] **Step 4: 运行种子测试确认 GREEN**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminRbacSeedTest test`

Expected: PASS。

### Task 2: 数据库登录、当前身份、角色实时收权与账号失效

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/mapper/AdminRbacMapper.java`
- Create: `backend/src/main/resources/mapper/AdminRbacMapper.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/model/AdminUserRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/model/AdminRoleRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/model/AdminPermissionRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/model/response/AdminMeResponse.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/service/AdminAuditLogService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/common/admin/AdminSession.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/service/AdminAuthService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/model/response/AdminLoginResponse.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthController.java`
- Modify: `backend/src/main/resources/application.yml`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthControllerTest.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/auth/service/AdminAuthServiceTest.java`

- [x] **Step 1: 编写数据库身份失败测试**

增加用例约束：登录响应包含 `regions=[CN,EU]`；`GET /auth/me` 返回实时权限；SQL 停用 `admin_user` 后旧 token 下一次请求返回 `401`。

```java
mockMvc.perform(get("/api/admin/v1/auth/me").header("Authorization", bearer(token)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.profile.account").value("admin"))
        .andExpect(jsonPath("$.data.permissions").isArray())
        .andExpect(jsonPath("$.data.regions[0]").value("CN"));

jdbc.update("UPDATE admin_user SET status=2 WHERE id=1");
mockMvc.perform(get("/api/admin/v1/menus").header("Authorization", bearer(token)))
        .andExpect(status().isUnauthorized());
```

- [x] **Step 2: 运行测试确认 RED**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminAuthControllerTest,AdminAuthServiceTest test`

Expected: FAIL，当前响应无 regions/auth-me，且登录仍依赖配置账号。

- [x] **Step 3: 实现数据库身份加载**

`AdminRbacMapper` 提供：

```java
AdminUserRow selectUserByAccount(String account);
AdminUserRow selectActiveUserById(Long adminId);
List<AdminRoleRow> selectActiveRolesByAdminId(Long adminId);
List<AdminPermissionRow> selectActivePermissionsByAdminId(Long adminId);
List<String> selectRegionsByAdminId(Long adminId);
int updateLastLoginAt(Long adminId);
void insertAuditLog(Long adminId, String action, String target, String detail, String ip);
```

`AdminSession` 改为：

```java
public record AdminSession(
        Long adminId,
        String account,
        String name,
        Set<String> permissions,
        Set<String> regions
) {}
```

`AdminAuthService` session store 只保存 `adminId/expiresAt`，`authenticate` 每次重新加载账号、权限和区域。登录使用 BCrypt，更新最近登录时间并返回实时 session。控制器把客户端 IP 传给登录服务；成功与失败都通过 `AdminAuditLogService` 写入 `audit_log`，失败日志使用 `admin_id=0`，且 detail 只保存脱敏账号。完成切换后从 `application.yml` 删除 `app.admin.account/password/name`，只保留 token TTL。

- [x] **Step 4: 运行身份测试确认 GREEN**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminAuthControllerTest,AdminAuthExpiryControllerTest,AdminAuthServiceTest test`

Expected: PASS。

### Task 3: 权限注解、403 和菜单过滤

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/common/api/ForbiddenException.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/AdminPermission.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/service/AdminPermissionChecker.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/service/AdminMenuService.java`
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/auth/AdminPermissionCoverageTest.java`
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminPermissionControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/common/api/GlobalExceptionHandler.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/AdminAuthInterceptor.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthController.java`
- Modify: all controllers whose `@RequestMapping` starts with `/api/admin/v1`

- [x] **Step 1: 编写权限与覆盖失败测试**

覆盖：受限管理员访问无权限接口返回 `403`；EU-only 管理员请求 `X-Region=CN` 返回 `403`；菜单不返回无权限叶子和空分组。反射测试扫描所有管理端 handler，allowlist 只包含 login/logout/me/menus。

```java
assertTrue(method.isAnnotationPresent(AdminPermission.class)
        || method.getDeclaringClass().isAnnotationPresent(AdminPermission.class));
```

- [x] **Step 2: 运行测试确认 RED**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminPermissionCoverageTest,AdminPermissionControllerTest test`

Expected: FAIL，注解和 403 处理不存在。

- [x] **Step 3: 实现权限检查和精确标注**

注解签名：

```java
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface AdminPermission {
    String value() default "";
    boolean regionScoped() default true;
    boolean dynamic() default false;
}
```

固定映射：

- shops GET → `data:shop:read`；POST/PUT/DELETE → `data:shop:write`
- import POST → `data:shop:import`；batches GET → `data:import_batch:read`
- merchant applications GET/POST → `audit:merchant_application:read/write`
- circle/topic/growth/rank GET → 对应 `:read`，写方法 → `:write`
- search reindex → `data:search_index:write`
- `AdminAuditController` → `@AdminPermission(dynamic=true)`

`AdminMenuService` 维护菜单 + requiredPermission，并按 session permissions 过滤。

- [x] **Step 4: 运行权限测试确认 GREEN**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminPermissionCoverageTest,AdminPermissionControllerTest,AdminAuthControllerTest test`

Expected: PASS。

### Task 4: 统一审核按 biz_type 动态鉴权

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/mapper/AdminAuditMapper.java`
- Modify: `backend/src/main/resources/mapper/AdminAuditMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/model/AdminAuditTaskQuery.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditServiceTest.java`

- [x] **Step 1: 编写动态审核失败测试**

约束权限映射：`biz_type=3 → audit:review:*`、`4 → audit:post:*`、`5 → audit:shop_change:*`、`6 → audit:review_appeal:*`、`2 → audit:deal:*`。无明确 bizType 的列表只能返回当前管理员具备 read 权限的类型。

- [x] **Step 2: 运行测试确认 RED**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminAuditServiceTest test`

Expected: FAIL，当前服务不读取 session 权限。

- [x] **Step 3: 实现对象级动态鉴权**

新增映射方法：

```java
private String permissionFor(Integer bizType, boolean write) {
    String action = write ? "write" : "read";
    return switch (bizType) {
        case 2 -> "audit:deal:" + action;
        case 3 -> "audit:review:" + action;
        case 4 -> "audit:post:" + action;
        case 5 -> "audit:shop_change:" + action;
        case 6 -> "audit:review_appeal:" + action;
        default -> throw new IllegalArgumentException("不支持的审核类型");
    };
}
```

列表查询增加内部 `allowedBizTypes`，SQL 使用 `IN` 过滤；通过/驳回先加载 task，再校验对应 write 权限。

- [x] **Step 4: 运行审核回归确认 GREEN**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminAuditServiceTest,AdminMerchantReviewAppealAuditControllerTest,AdminShopChangeAuditControllerTest test`

Expected: PASS。

### Task 5: RBAC 角色、管理员和审计接口

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/controller/AdminRbacController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/service/AdminRbacService.java`
- Create request records under `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/model/request/`
- Create response records under `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/model/response/`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/rbac/mapper/AdminRbacMapper.java`
- Modify: `backend/src/main/resources/mapper/AdminRbacMapper.xml`
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/rbac/AdminRbacControllerTest.java`

- [x] **Step 1: 编写 RBAC CRUD 失败测试**

覆盖权限列表、角色创建编辑启停删除、管理员创建编辑启停重置密码；断言自停用、最后超级管理员、停用角色引用、空角色/区域、重复账号/角色码和 super_admin 修改均被拦截。

- [x] **Step 2: 运行测试确认 RED**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminRbacControllerTest test`

Expected: FAIL，`/rbac/**` 不存在。

- [x] **Step 3: 实现事务服务和接口**

请求类型必须明确：

```java
record AdminRoleSaveRequest(String code, String name, String description, List<Long> permissionIds) {}
record AdminUserCreateRequest(String account, String password, String name, List<Long> roleIds, List<String> regions) {}
record AdminUserUpdateRequest(String name, List<Long> roleIds, List<String> regions) {}
record AdminStatusRequest(Integer status) {}
record AdminPasswordResetRequest(String password) {}
```

所有关联替换在 `@Transactional` 中完成。`DELETE /admins/{id}` 只把 status 改为 2。审计 detail 使用 JSON 摘要，但排除 password/passwordHash/token。

- [x] **Step 4: 运行 RBAC 测试确认 GREEN**

Run: `cd backend; .\mvnw.cmd -Dtest=AdminRbacControllerTest,AdminAuthControllerTest,AdminPermissionControllerTest test`

Expected: PASS。

### Task 6: 前端身份、服务与路由权限基础

**Files:**
- Create: `admin-web/src/services/admin-rbac.test.ts`
- Create: `admin-web/src/composables/useAdminSession.test.ts`
- Create: `admin-web/src/router/index.test.ts`
- Modify: `admin-web/src/types/admin.ts`
- Modify: `admin-web/src/services/admin.ts`
- Modify: `admin-web/src/composables/useAdminSession.ts`
- Modify: `admin-web/src/views/LoginView.vue`
- Modify: `admin-web/src/layouts/AdminLayout.vue`
- Modify: `admin-web/src/router/index.ts`

- [x] **Step 1: 编写前端基础失败测试**

断言：登录保存 regions；`fetchAdminMe` 刷新 profile/permissions/regions；管理员和角色服务使用 `/api/admin/v1/rbac/**`；无 requiredPermission 的账号被路由重定向到 `/dashboard`；过期 token 清理后回 `/login`。

- [x] **Step 2: 运行测试确认 RED**

Run: `cd admin-web; npm test -- src/services/admin-rbac.test.ts src/composables/useAdminSession.test.ts src/router/index.test.ts`

Expected: FAIL，regions、auth/me 和 RBAC 服务不存在。

- [x] **Step 3: 实现类型、会话刷新和路由守卫**

新增类型：

```ts
interface AdminIdentity { profile: AdminProfile; permissions: string[]; regions: Region[] }
interface AdminRole { id: number; code: string; name: string; description: string; status: number; builtIn: boolean; permissionIds: number[]; adminCount: number }
interface AdminPermissionItem { id: number; code: string; name: string; category: string; type: number }
interface AdminAccount { id: number; account: string; name: string; status: number; roleIds: number[]; roleNames: string[]; regions: Region[]; lastLoginAt: string }
```

路由增加 `/system/admins`、`/system/roles` 和 `meta.requiredPermission`。布局加载菜单前调用 `fetchAdminMe()` 刷新权限；403 只显示错误，不清 token。

- [x] **Step 4: 运行基础测试确认 GREEN**

Run 同 Step 2。

Expected: PASS。

### Task 7: 管理员账号页面

**Files:**
- Create: `admin-web/src/views/AdminAccountsView.vue`
- Create: `admin-web/src/views/AdminAccountsView.test.ts`
- Modify: `admin-web/src/style.css`

- [x] **Step 1: 编写管理员页面失败测试**

覆盖分页加载、创建、编辑角色/区域、启停、重置密码、当前账号保护和后端失败时保留弹层输入。

- [x] **Step 2: 运行测试确认 RED**

Run: `cd admin-web; npm test -- src/views/AdminAccountsView.test.ts`

Expected: FAIL，页面不存在。

- [x] **Step 3: 实现管理员页面**

页面使用现有 `page-shell/card/table/dialog` 视觉语言；密码字段仅在创建和重置弹层出现，关闭弹层时清空。角色、区域至少选一个；危险操作显示保护原因。

- [x] **Step 4: 运行页面测试确认 GREEN**

Run 同 Step 2。

Expected: PASS。

### Task 8: 角色与权限页面

**Files:**
- Create: `admin-web/src/views/AdminRolesView.vue`
- Create: `admin-web/src/views/AdminRolesView.test.ts`
- Modify: `admin-web/src/style.css`

- [x] **Step 1: 编写角色页面失败测试**

覆盖权限按 category 分组、创建/编辑、内置角色限制、super_admin 只读权限、启停、删除和引用冲突错误保留表单。

- [x] **Step 2: 运行测试确认 RED**

Run: `cd admin-web; npm test -- src/views/AdminRolesView.test.ts`

Expected: FAIL，页面不存在。

- [x] **Step 3: 实现角色页面**

权限组固定显示 `审核中心/数据管理/运营配置/系统管理`；checkbox label 同时展示名称和 code。`super_admin` 权限与状态控件禁用，普通内置角色禁用 code 和删除按钮。

- [x] **Step 4: 运行页面测试确认 GREEN**

Run 同 Step 2。

Expected: PASS。

### Task 9: 全量验证、浏览器验收和文档同步

**Files:**
- Modify: `README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/测试清单与验收用例.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/权限矩阵.md`
- Modify: `docs/superpowers/plans/2026-07-18-admin-rbac-foundation.md`

- [x] **Step 1: 运行后端与前端全量验证**

Run:

```powershell
cd backend; .\mvnw.cmd -q test
cd ..\admin-web; npm test; npm run build
```

Result: 后端 `212` 条测试通过；管理端 `12` 个测试文件、`25` 条测试通过，构建退出码 `0`。

- [x] **Step 2: 运行脚本契约**

Run: 执行全部 `scripts/ci/test-*.ps1`。

Result: 全部 `10` 个 `scripts/ci/test-*.ps1` 契约通过。

- [x] **Step 3: 使用 H2 真实浏览器验收**

验证：超级管理员登录并看到系统管理菜单；创建 EU-only 审核员；受限账号登录只看到授权菜单；访问无权限路由被拦截；CN 请求返回 403；角色停用后 `auth/me` 仍为 `200` 但权限收回，固定受限 API 返回 `403`、动态审核列表可为空；管理员账号停用后旧 token 返回 `401` 并清理前端会话；控制台无新增错误。

- [x] **Step 4: 同步事实文档**

已将“管理员数据库 RBAC”从剩余工作移除；分类/城市/商圈、用户治理、订单/退款/对账、运营活动、审计日志和隐私任务查询仍保留为未完成。

> 实际浏览器结果：`browser-smoke` 通过 `7/7`，真实后端 `browser-e2e` 通过 `5/5`；覆盖创建 EU-only 审核员、菜单/路由/API 越权、角色停用后的实时收权，以及账号停用后旧 token 返回 `401`、重载时清理旧 `localStorage` 会话。
