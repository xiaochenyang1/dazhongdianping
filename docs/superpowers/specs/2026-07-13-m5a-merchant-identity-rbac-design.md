# M5a 商户身份、入驻与 RBAC 设计

## 1. 目标与边界

本阶段把当前“配置文件里只有一个演示商户账号”的骨架替换为数据库驱动的商户身份体系，完成商户注册、资质提交、运营审核、主账号/员工登录、角色授权和门店范围隔离。

本阶段不实现门店编辑、团购编辑、订单退款、点评回复、预订列表和经营看板；这些能力在 M5b 复用本阶段的权限服务。本阶段也不创建 `merchant-web`，M5c 再建设独立前端。

## 2. 领域模型

- `merchant` 继续表示企业或个体经营主体，保留公司名、联系人、区域、审核状态和启停状态。
- `merchant_operator` 表示可登录操作者。`operator_type=1` 为主账号，`2` 为员工；账号全局唯一，密码使用 BCrypt；员工必须归属于一个商户。
- `merchant_role` 保存内置角色：`owner`、`store_manager`、`coupon_operator`、`service_operator`，权限用逗号分隔的稳定权限码保存。
- `merchant_operator_role` 关联操作者与角色。
- `merchant_operator_shop` 保存指定门店范围；`shop_scope_type=1` 表示商户全部门店，`2` 表示仅关联门店。
- `merchant_application` 保存营业执照、法人、门店照片、提交时间、审核状态、驳回原因和审核人。每个商户保留一条当前申请，驳回后覆盖重提并保留 `updated_at`。

## 3. 认证与会话

`MerchantAuthService` 改为从 `merchant_operator` 查询账号并校验 BCrypt 密码。登录只要求操作者和商户未停用；待审核主账号可以登录查看/补交资质，但访问经营工作台时仍由 `MerchantWorkbenchService` 拦截，只有 `merchant.audit_status=1` 才可进入。

`MerchantSession` 扩展为 `operatorId、merchantId、account、operatorType`。访问令牌继续使用当前带过期时间的服务内会话存储，避免在 M5a 同时引入新的分布式会话问题；后续可无缝换 Redis。

注册成功后立即创建：待审核 `merchant`、主账号 `merchant_operator`、`owner` 角色关联，并返回访问令牌。这样新商户不必退出再登录即可提交资质。

## 4. 权限与门店范围

新增 `MerchantAuthorizationService`：

- `requirePermission(permission)` 校验当前操作者角色是否包含权限。
- `requireShop(permission, shopId)` 同时校验权限、门店属于当前商户，以及员工的门店范围。
- 主账号绑定 `owner`，拥有全部 M5 权限且默认全部门店。
- 员工列表、创建、编辑、启停只允许 `staff:manage`。
- 员工不能修改主账号，也不能把门店范围指向其他商户门店。
- 后续 M5b 的券核销、预订、门店和团购动作统一调用该服务，SQL 仍保留商户归属条件，形成 service + SQL 双层隔离。

## 5. API

### 商户端

- `POST /api/b/v1/auth/register`
- `POST /api/b/v1/auth/login`
- `POST /api/b/v1/settle/apply`
- `GET /api/b/v1/settle/status`
- `GET /api/b/v1/account/me`
- `GET /api/b/v1/roles`
- `GET /api/b/v1/staffs`
- `POST /api/b/v1/staffs`
- `PUT /api/b/v1/staffs/{id}`
- `PUT /api/b/v1/staffs/{id}/status`

注册请求包含 `account、password、companyName、contactName、contactPhone、region`。资质请求包含 `licenseUrl、legalPerson、shopPhotoUrls`。员工创建/编辑请求严格遵循 `docs/接口设计.md` 的 `roleIds、shopScopeType、shopIds` 契约。

### 管理端

- `GET /api/admin/v1/merchant-applications`
- `POST /api/admin/v1/merchant-applications/{merchantId}/audit`

审核请求 `status` 只允许 `1通过` 或 `2驳回`；驳回必须填写 `reason`。审核通过同步 `merchant.audit_status=1`，驳回同步为 `2`。

## 6. 错误与安全

- 重复账号、跨商户角色/门店、停用员工、错误密码返回明确的 `400/401/404`，不泄露其他商户详情。
- 密码永不以明文落库或返回。
- 注册、资质提交、员工写操作和审核操作均受现有 `Idempotency-Key` 保护。
- 所有列表按当前商户过滤；员工账号登录后只能看到被授权门店。
- 运营审核写现有 `admin_audit_log`，员工创建/编辑/启停写新增 `merchant_operation_log`。

## 7. 测试与验收

- 集成测试覆盖注册、资质提交、待审核状态、管理员通过/驳回、数据库账号登录。
- 集成测试覆盖主账号创建员工、员工登录、角色权限和指定门店范围。
- 安全测试覆盖重复账号、员工修改主账号、跨商户门店授权、停用后令牌失效、错区域访问。
- 同步验证 H2 与 MySQL 脚本，运行后端全量测试和 `scripts/ci/verify-all.ps1`。

## 8. 自审结论

本文无待定项。M5a 只提供身份与授权基础，不提前塞入 M5b 经营逻辑；当前内存令牌存储是明确的阶段性边界，不影响数据库账号与权限成为权威源。
