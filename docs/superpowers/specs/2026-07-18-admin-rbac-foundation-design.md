# 管理端数据库 RBAC 基础设计

> **状态：** 用户已批准总体方案与本子项目方向；本文用于锁定数据库管理员身份、角色权限、区域范围、菜单过滤和管理页面的实现边界。

## 目标

把管理端从“配置文件中的单个明文账号 + 固定权限列表 + 内存身份快照”升级为数据库管理员与 RBAC：

- 管理员账号、BCrypt 密码、角色、权限和区域范围进入 H2/MySQL。
- 当前 `admin / admin123456` 演示登录契约继续可用，但账号信息不再来自 `application.yml`。
- 后端接口权限、区域数据权限和前端菜单使用同一套权限码。
- 管理员停用、角色停用、权限或区域变更对现有 token 立即生效。
- 管理端提供管理员账号和角色维护页面，关键变更写入 `audit_log`。

本子项目只建设后续治理功能依赖的权限底座，不同时实现分类、城市、商圈、用户、订单、运营活动和审计日志查询页面。

## 方案选择

采用“现有 MVC 拦截器 + 数据库 RBAC + 权限注解”的渐进方案。

未选择全面迁移 Spring Security，是因为当前管理端已经有独立 interceptor、异常模型和 opaque token；一次性替换整个安全栈会扩大回归范围，却不会给一期 RBAC 带来等价收益。也不保留配置账号与数据库账号双轨兜底，双来源会造成权限、停用状态和审计归属互相打架。

## 数据模型

### `admin_user`

| 字段 | 说明 |
|---|---|
| `id` | 管理员 ID |
| `account` | 唯一登录账号，统一 trim 后保存 |
| `password_hash` | BCrypt 哈希，不保存明文密码 |
| `name` | 展示姓名 |
| `status` | `1` 正常，`2` 停用 |
| `last_login_at` | 最近成功登录时间 |
| `created_at/updated_at` | 创建与更新时间 |

### `admin_role`

| 字段 | 说明 |
|---|---|
| `id` | 角色 ID |
| `code` | 唯一角色码 |
| `name` | 角色名称 |
| `description` | 权限边界说明 |
| `status` | `1` 正常，`2` 停用 |
| `built_in` | 是否内置角色；内置角色不可删除或修改角色码 |
| `created_at/updated_at` | 创建与更新时间 |

### `admin_permission`

| 字段 | 说明 |
|---|---|
| `id` | 权限 ID |
| `code` | 唯一权限码 |
| `name` | 权限名称 |
| `category` | `dashboard/audit/data/operations/system` |
| `type` | `1` 菜单，`2` 动作，`3` 接口 |
| `status` | `1` 正常，`2` 停用 |

菜单结构继续由代码维护，数据库只保存可授权的权限点。这样避免把 Vue 路由、菜单层级和接口地址硬塞进数据库，权限表也不会沦为另一个低配 CMS。

### 关联表

- `admin_user_role(admin_id, role_id)`：管理员角色。
- `admin_role_permission(role_id, permission_id)`：角色权限。
- `admin_region_scope(admin_id, region)`：管理员允许操作的区域，当前只允许 `CN/EU`。

管理员创建时至少选择一个角色和一个区域。角色和区域更新采用事务内“校验全部引用 → 删除旧关联 → 写入新关联”，任何一步失败均回滚。

## 内置账号、角色和权限

初始账号：

- `admin / admin123456`
- `name=系统管理员`
- 角色 `super_admin`
- 区域 `CN`、`EU`
- 密码在种子 SQL 中使用 BCrypt 哈希。

一期内置角色：

- `super_admin`：全部现有权限和 RBAC 管理权限；角色码、状态和权限集合不可通过管理接口修改，新增权限必须在同一数据库变更中授予该角色。
- `content_auditor`：点评、帖子和商户点评申诉查看/审核。
- `merchant_auditor`：商户资质、团购和门店变更查看/审核。
- `operations_manager`：榜单、成长、圈子和话题配置。
- `data_operator`：门店查看/维护、种子导入和导入批次查看。

权限码按业务对象拆分读写，禁止继续使用一个 `audit_task:write` 把所有审核员揉成万能钥匙。首批权限包括：

- `dashboard:read`
- `audit:review:read/write`
- `audit:post:read/write`
- `audit:review_appeal:read/write`
- `audit:merchant_application:read/write`
- `audit:deal:read/write`
- `audit:shop_change:read/write`
- `data:shop:read/write/import`
- `data:import_batch:read`
- `data:search_index:write`
- `operations:rank:read/write`
- `operations:growth:read/write`
- `operations:circle:read/write`
- `operations:topic:read/write`
- `system:admin:read/write`
- `system:role:read/write`
- `system:permission:read`

后续用户治理、财务、合规和运营活动子项目新增自己的权限点和内置角色，不在本阶段预埋一堆没有接口消费者的空权限。

## 登录与会话

`AdminAuthService` 不再注入配置账号、密码和姓名，登录流程改为：

1. 按标准化账号查询 `admin_user`。
2. 校验账号状态和 BCrypt 密码。
3. 查询有效角色、有效权限和区域范围。
4. 更新 `last_login_at`，写登录成功审计。
5. 签发 opaque token。

内存 session store 暂时保留，但只保存 `adminId + expiresAt`。每次认证都重新查询管理员状态、有效角色、权限和区域范围，再构造当前请求的 `AdminSession`。因此账号停用、角色停用、权限回收或区域调整不需要等 token 过期。

本阶段不把管理端 token 迁移 Redis；多节点会话属于目标环境基础设施子项目，不能为了“看着高级”把 RBAC 和分布式会话搅成一锅。

`AdminSession` 增加：

- `permissions: Set<String>`
- `regions: Set<String>`

登录响应保留 `accessToken/tokenType/profile/permissions` 结构，并增加 `regions`。新增 `GET /api/admin/v1/auth/me`，供页面刷新时重新获取当前身份、权限和区域范围，避免长期相信 localStorage 中的旧权限快照。

## 接口权限与区域范围

新增 `@AdminPermission` 注解，可标在控制器类或方法上：

```java
@AdminPermission(value = "audit:merchant_application:write", regionScoped = true)
```

统一审核接口的真实权限取决于 `audit_task.biz_type`，因此注解支持 `dynamic=true`。该模式仍执行登录和区域校验，具体权限由 `AdminAuditService` 在读取任务类型后按 `review/post/review_appeal/deal/shop_change` 映射检查；它不是跳过鉴权的后门。

`AdminAuthInterceptor` 在完成 token 认证后：

1. 获取 `HandlerMethod` 上的方法级或类级权限注解。
2. 校验当前 session 是否包含权限码。
3. 当 `regionScoped=true` 时，校验当前 `X-Region` 是否在 `session.regions` 中。
4. 权限或区域不符时返回 `403`，不使用 `404` 掩盖内部配置错误。

`/auth/login` 不经过管理端鉴权；`/auth/logout`、`/auth/me`、`/menus` 只要求有效会话；`/rbac/**` 使用系统权限且 `regionScoped=false`。其他管理端业务接口必须显式声明固定权限或 `dynamic=true`，不允许靠“登录了就随便干”。

## 菜单过滤

菜单结构仍保存在后端代码中，但每个叶子菜单绑定 `requiredPermission`。`GET /menus` 根据当前 session 的权限过滤叶子菜单，并删除没有可见子项的空分组。

新增系统菜单：

- `system.admins` → `/system/admins`，要求 `system:admin:read`。
- `system.roles` → `/system/roles`，要求 `system:role:read`。

前端路由 `meta.requiredPermission` 用于导航体验和直接访问拦截；后端注解仍是唯一安全边界。

## RBAC 管理接口

### 权限点

- `GET /api/admin/v1/rbac/permissions`
- 只返回有效权限点，按 `category/code` 排序。
- 权限点由代码和种子数据共同维护，本阶段不允许前台创建或删除权限码。

### 角色

- `GET /rbac/roles`
- `POST /rbac/roles`
- `PUT /rbac/roles/{id}`
- `PUT /rbac/roles/{id}/status`
- `DELETE /rbac/roles/{id}`

角色保存 payload 包含 `code/name/description/permissionIds`。内置角色不可删除、不可修改 `code`；`super_admin` 额外禁止停用或修改权限集合；被管理员引用的自定义角色不可删除；停用角色后其权限在现有 token 的下一次请求立即失效。

### 管理员账号

- `GET /rbac/admins`
- `POST /rbac/admins`
- `PUT /rbac/admins/{id}`
- `PUT /rbac/admins/{id}/status`
- `PUT /rbac/admins/{id}/password`
- `DELETE /rbac/admins/{id}`：逻辑停用，不物理删除审计主体。

账号保存 payload 包含 `account/name/roleIds/regions`；创建时包含不少于 8 位的初始密码。密码重置单独使用接口，任何响应和审计详情都不得包含密码或哈希。

系统必须阻止：

- 当前管理员停用或删除自己。
- 停用、删除或移除最后一个有效 `super_admin` 账号的超级管理员角色。
- 为账号绑定不存在或已停用的角色。
- 提交空角色、空区域、非法区域或重复账号。

## 管理端页面

新增两个页面：

### `/system/admins`

- 分页查看账号、状态、角色、区域和最近登录时间。
- 创建管理员、编辑姓名/角色/区域。
- 启停账号和重置密码。
- 当前账号和最后一个超级管理员的危险操作按钮禁用，并展示明确原因。

### `/system/roles`

- 查看内置/自定义角色、状态、管理员引用数和权限摘要。
- 创建或编辑自定义角色。
- 权限按 `审核中心/数据管理/运营配置/系统管理` 分组展示。
- 普通内置角色只能修改名称、描述、权限和状态，不能修改角色码或删除；`super_admin` 只能修改名称和描述。

`useAdminSession` 保存 `regions`，登录和 `auth/me` 都会刷新 permissions/regions。路由守卫发现本地 token 已失效时必须清空会话并回登录页，不能重演商户端那种白屏闹剧。

## 审计日志

新增集中式 `AdminAuditLogService`，本阶段记录：

- 登录成功、登录失败。
- 管理员创建、编辑、启停、重置密码。
- 角色创建、编辑、启停、删除。

审计详情只保存目标 ID、变更字段名、角色 ID 和区域，不保存密码、密码哈希、token 或完整敏感请求。登录失败使用 `admin_id=0` 并保存脱敏账号与来源 IP。

现有审核和导入服务的审计写入暂不重构，只保证新 RBAC 功能走统一服务；审计查询页面在后续治理子项目实现。

## 错误语义

- `401`：登录失败、token 不存在或过期、账号已停用。
- `403`：缺少权限或区域范围不包含当前区域。
- `404`：管理员、角色或权限引用不存在。
- `409`：重复账号/角色码、角色仍被引用、最后一个超级管理员保护、当前账号自停用。
- `400`：密码长度、空角色、空区域或非法枚举。

错误响应继续使用现有 API envelope 和稳定中文业务消息，不暴露 SQL、哈希、token 或权限内部实现。

## 数据迁移与兼容

- H2 `schema.sql/data.sql` 与 MySQL `01_schema.sql/02_seed_data.sql` 同步新增全部 RBAC 表和种子。
- 初始管理员 ID 固定为 `1`，兼容现有 `audit_log.admin_id=1` 和测试假设。
- 删除 `app.admin.account/password/name` 配置，只保留 token TTL 配置。
- 当前前端登录响应结构向后兼容，新增字段不破坏现有调用。
- 现有所有管理端控制器在本阶段完成权限标注，避免出现一半受控、一半裸奔的过渡状态。

## 测试与运行证据

### 后端

- Mapper 集成测试：管理员、角色、权限、区域和 BCrypt 种子正确。
- 登录测试：正确密码、错误密码、停用账号、过期 token、登出。
- 即时失效测试：账号停用、角色停用、权限回收和区域调整对旧 token 生效。
- 权限注解测试：无权限返回 `403`，读写权限隔离，区域越权返回 `403`。
- 注解覆盖契约测试：除明确列入 allowlist 的登录、登出、身份和菜单接口外，所有 `/api/admin/v1` 控制器方法都必须声明 `@AdminPermission`，防止新增接口漏鉴权。
- 菜单测试：不同角色只返回允许菜单，空分组被移除。
- RBAC CRUD 测试：角色/管理员创建编辑启停、引用保护、自停用保护、最后超级管理员保护。
- 审计测试：关键操作落日志且不包含密码、哈希和 token。

### 前端

- 服务契约测试：`auth/me`、管理员、角色、权限接口路径和 payload。
- 会话测试：permissions/regions 持久化、刷新和清理。
- 路由/布局测试：菜单与直接路由按权限隐藏或拦截。
- 管理员页面测试：创建、编辑、启停、重置密码和保护提示。
- 角色页面测试：权限分组、内置角色限制和引用错误保留表单状态。

### 验收

- 后端全量测试通过。
- `admin-web` 全量测试和生产构建通过。
- H2 浏览器链路验证：超级管理员登录 → 创建受限审核员 → 受限账号登录 → 只看到允许菜单 → 跨区域或无权限操作返回明确提示。
- 所有 `scripts/ci/test-*.ps1` 契约通过。

## 非目标

本阶段不实现：

- Redis/数据库持久化 token、多节点会话和单点登录。
- MFA、LDAP、OAuth、企业 SSO、密码找回和强制轮换策略。
- 城市/门店级管理员数据范围；一期只做 `CN/EU` 区域范围。
- 分类、地理、用户、订单、对账、Banner、热词、运营活动和审计查询业务页面。
- 字段级权限和前端可配置菜单结构。

这些能力分别进入后续治理或目标环境子项目，不能借 RBAC 之名把范围膨胀成一艘永远造不完的航空母舰。
