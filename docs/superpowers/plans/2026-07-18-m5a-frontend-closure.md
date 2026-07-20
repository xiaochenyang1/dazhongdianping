# M5a Frontend Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐商户注册、资质、员工管理和管理端商户审核页面，形成 M5a 跨端闭环。

**Architecture:** 复用现有 M5a 后端 API，不改身份状态机。`merchant-web` 使用显式类型和独立公开/资质/经营路由；`admin-web` 增加资质审核视图，两个前端都沿用现有 API envelope、区域头和会话机制。

**Tech Stack:** Vue 3、TypeScript、Vue Router、Vitest/jsdom、现有 Axios 封装

---

### Task 1: 锁定商户身份 API 类型和请求契约

**Files:**
- Create: `merchant-web/src/services/merchant.test.ts`
- Modify: `merchant-web/src/services/merchant.ts`

- [x] **Step 1: 编写失败服务测试**

使用 `vi.mock('@/lib/http')` 断言以下调用：

```ts
expect(apiPost).toHaveBeenCalledWith('/api/b/v1/auth/register', registration)
expect(apiGet).toHaveBeenCalledWith('/api/b/v1/settle/status')
expect(apiPost).toHaveBeenCalledWith('/api/b/v1/settle/apply', settlement)
expect(apiGet).toHaveBeenCalledWith('/api/b/v1/staffs', { page: 1, pageSize: 20 })
expect(apiPut).toHaveBeenCalledWith('/api/b/v1/staffs/9/status', { status: 2 })
```

- [x] **Step 2: 运行测试确认 RED**

Run: `npm test -- src/services/merchant.test.ts`

Expected: FAIL，注册、资质或员工函数未导出。

- [x] **Step 3: 增加显式类型与服务函数**

增加 `MerchantRegistrationPayload/Result`、`SettlementStatus/Payload`、`MerchantAccount`、`MerchantRole`、`MerchantStaff`、`MerchantStaffPayload`、`MerchantShopOption`，以及：

```ts
registerMerchant(payload)
fetchSettlementStatus()
submitSettlement(payload)
fetchStaffs(params)
createStaff(payload)
updateStaff(id, payload)
updateStaffStatus(id, status)
```

- [x] **Step 4: 运行服务测试确认 GREEN**

Run: `npm test -- src/services/merchant.test.ts`

Expected: PASS。

### Task 2: 扩展会话并完成商户注册页

**Files:**
- Modify: `merchant-web/src/composables/useMerchantSession.ts`
- Modify: `merchant-web/src/composables/useMerchantSession.test.ts`
- Create: `merchant-web/src/views/RegisterView.vue`
- Create: `merchant-web/src/views/RegisterView.test.ts`
- Modify: `merchant-web/src/views/LoginView.vue`
- Modify: `merchant-web/src/router/index.ts`

- [x] **Step 1: 为区域持久化和注册跳转编写失败测试**

会话测试要求 `setSession` 接收可选 `region` 并同步 `state.region/localStorage`。注册页测试填写表单后断言：

```ts
expect(registerMerchant).toHaveBeenCalledWith({
  account: 'owner@example.com',
  password: 'Merchant#123456',
  companyName: 'North Star Foods',
  contactName: 'Alice',
  contactPhone: '+33123456789',
  region: 'EU',
})
expect(setSession).toHaveBeenCalled()
expect(router.replace).toHaveBeenCalledWith('/settlement')
```

- [x] **Step 2: 运行测试确认 RED**

Run: `npm test -- src/composables/useMerchantSession.test.ts src/views/RegisterView.test.ts`

Expected: FAIL，`region` 未持久化或注册视图不存在。

- [x] **Step 3: 实现会话和注册页**

注册表单使用 `autocomplete`、最小密码长度、提交禁用和后端错误回显。登录页增加 `/register` 链接；路由将 `/register` 设为公开页。

- [x] **Step 4: 运行测试确认 GREEN**

Run: `npm test -- src/composables/useMerchantSession.test.ts src/views/RegisterView.test.ts`

Expected: PASS。

### Task 3: 完成资质状态、提交与登录分流

**Files:**
- Create: `merchant-web/src/views/SettlementView.vue`
- Create: `merchant-web/src/views/SettlementView.test.ts`
- Modify: `merchant-web/src/views/LoginView.vue`
- Modify: `merchant-web/src/router/index.ts`
- Modify: `merchant-web/src/lib/http.ts`

- [x] **Step 1: 编写资质页失败测试**

覆盖未提交表单、驳回原因与重提、待审只读、已通过入口。登录测试要求登录后调用 `fetchSettlementStatus`：状态 `1` 进入原重定向，其余进入 `/settlement`。

- [x] **Step 2: 运行测试确认 RED**

Run: `npm test -- src/views/SettlementView.test.ts src/views/LoginView.test.ts`

Expected: FAIL，资质页或登录分流不存在。

- [x] **Step 3: 实现资质页和错误语义**

`/settlement` 需要 token，但不挂经营布局。`lib/http.ts` 对消息 `商户资质尚未审核通过` 的 `401` 不清空 token；其他 `401` 仍清空会话。

- [x] **Step 4: 运行测试确认 GREEN**

Run: `npm test -- src/views/SettlementView.test.ts src/views/LoginView.test.ts`

Expected: PASS。

### Task 4: 完成员工权限与门店范围管理

**Files:**
- Create: `merchant-web/src/views/StaffsView.vue`
- Create: `merchant-web/src/views/StaffsView.test.ts`
- Modify: `merchant-web/src/layouts/MerchantLayout.vue`
- Modify: `merchant-web/src/router/index.ts`
- Modify: `merchant-web/src/style.css`

- [x] **Step 1: 编写员工页面失败测试**

覆盖加载员工/角色/门店、过滤 `owner`、指定门店必选、创建、编辑、启停和权限不足时不显示入口。

- [x] **Step 2: 运行测试确认 RED**

Run: `npm test -- src/views/StaffsView.test.ts`

Expected: FAIL，员工视图不存在。

- [x] **Step 3: 实现员工页面和权限导航**

布局加载 `fetchAccount`，仅当 `permissions.includes('staff:manage')` 时显示 `/staffs`。员工弹层保存 `roleIds/shopScopeType/shopIds`，状态按钮成功后刷新当前页。

- [x] **Step 4: 运行测试确认 GREEN**

Run: `npm test -- src/views/StaffsView.test.ts`

Expected: PASS。

### Task 5: 完成管理端商户资质审核

**Files:**
- Modify: `admin-web/src/types/admin.ts`
- Modify: `admin-web/src/services/admin.ts`
- Create: `admin-web/src/views/MerchantApplicationAuditView.vue`
- Create: `admin-web/src/views/MerchantApplicationAuditView.test.ts`
- Modify: `admin-web/src/router/index.ts`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthController.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthControllerTest.java`

- [x] **Step 1: 编写前后端失败测试**

前端测试覆盖按状态加载、通过、空原因驳回拦截、后端失败保留状态。后端菜单测试要求返回 `/audit/merchant-applications`。

- [x] **Step 2: 运行测试确认 RED**

Run:

```powershell
cd admin-web; npm test -- src/views/MerchantApplicationAuditView.test.ts
cd ..\backend; .\mvnw.cmd -Dtest=AdminAuthControllerTest test
```

Expected: FAIL，视图和菜单项不存在。

- [x] **Step 3: 实现类型、服务、页面、路由和菜单**

新增 `AdminMerchantApplication` 类型以及：

```ts
listMerchantApplications({ status, page, pageSize })
auditMerchantApplication(merchantId, { status, reason })
```

页面使用真实图片 URL、状态标签和审核动作；菜单归入“审核中心”。

- [x] **Step 4: 运行聚焦测试确认 GREEN**

Run 同 Step 2。

Expected: PASS。

### Task 6: 全量验证与文档同步

**Files:**
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `README.md`
- Modify: `docs/测试清单与验收用例.md`
- Modify: `docs/superpowers/plans/2026-07-18-m5a-frontend-closure.md`

- [x] **Step 1: 运行两个前端全量测试和构建**

Run:

```powershell
cd merchant-web; npm test; npm run build
cd ..\admin-web; npm test; npm run build
```

Expected: 全部退出码为 `0`。

- [x] **Step 2: 运行后端全量测试**

Run: `cd backend; .\mvnw.cmd test`

Expected: `BUILD SUCCESS`，零失败。

- [x] **Step 3: 更新功能矩阵**

将“商户端与管理端完整闭环”的剩余工作移除“商户注册/资质/员工页面”和“管理端商户审核”，保留管理员 RBAC、基础数据、用户、订单、运营活动和审计查询。

- [x] **Step 4: 标记计划步骤并运行文档契约**

Run: `.\scripts\ci\test-doc-status-consistency.ps1`

Expected: PASS。

> 当前目录无 Git 元数据，不能创建 worktree 或提交；测试与计划勾选作为阶段检查点。
