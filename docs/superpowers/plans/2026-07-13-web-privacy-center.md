# Web Privacy Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为现有隐私中心后端补齐可用的 Web 页面、认证下载、路由入口和自动化回归。

**Architecture:** 新增独立 `PrivacyCenterView.vue`，通过 `services/privacy.ts` 调用现有 `/api/c/v1/privacy` 接口；`lib/http.ts` 增加认证 Blob 下载能力。资料页只增加路由入口，避免继续堆积业务逻辑。

**Tech Stack:** Vue 3、TypeScript、Axios、Vitest、Playwright、Spring Boot H2 E2E

---

### Task 1: 隐私服务契约

**Files:**
- Create: `web/src/types/privacy.ts`
- Create: `web/src/services/privacy.ts`
- Create: `web/src/services/privacy.test.ts`
- Modify: `web/src/lib/http.ts`

- [ ] **Step 1: Write the failing service tests**

覆盖 `overview`、导出列表、创建导出、下载、创建删除和撤销的精确 URL、方法和参数。

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/services/privacy.test.ts`
Expected: FAIL，因为 `services/privacy.ts` 与下载 helper 尚不存在。

- [ ] **Step 3: Implement minimal typed service and authenticated blob download**

新增隐私响应类型、服务函数和 `apiDownload`；下载请求复用现有鉴权、区域头与 refresh 重试逻辑。

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- src/services/privacy.test.ts`
Expected: PASS。

### Task 2: 隐私中心页面与路由

**Files:**
- Create: `web/src/views/PrivacyCenterView.vue`
- Create: `web/src/views/PrivacyCenterView.test.ts`
- Modify: `web/src/router/index.ts`
- Modify: `web/src/views/ProfileView.vue`
- Modify: `web/src/style.css`

- [ ] **Step 1: Write the failing view test**

挂载页面并 mock 隐私服务，断言规则、导出任务、创建/下载、注销校验和撤销入口可用。

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/views/PrivacyCenterView.test.ts`
Expected: FAIL，因为页面尚不存在。

- [ ] **Step 3: Implement the page and protected route**

页面使用独立导出与注销分区；加入 `/user/privacy` 受保护路由，并从资料页提供入口。

- [ ] **Step 4: Run focused tests and build**

Run: `npm test -- src/views/PrivacyCenterView.test.ts src/router/auth-guard.test.ts`
Expected: PASS。

Run: `npm run build`
Expected: PASS。

### Task 3: 真实后端 E2E

**Files:**
- Modify: `web/e2e/real-backend-flow.spec.ts`

- [ ] **Step 1: Add the failing privacy flow scenario**

使用演示账号登录，进入隐私中心，创建导出任务并验证下载按钮，再创建删除任务并撤销。

- [ ] **Step 2: Run real backend E2E to verify the new scenario**

Run: `.\\scripts\\ci\\browser-e2e.ps1`
Expected: 新场景在实现完成前失败，实现完成后全部通过。

### Task 4: 文档与完整验证

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/前后端联调记录.md`

- [ ] **Step 1: Synchronize current-state documentation**

补充隐私中心后端与 Web 闭环，并把后端测试数量从历史 `85` 更新为当前实测数量。

- [ ] **Step 2: Run full verification**

Run: `.\\scripts\\ci\\verify-all.ps1`
Expected: 所有契约检查、后端测试、Web 测试与两套前端构建通过。

Run: `.\\scripts\\ci\\browser-smoke.ps1`
Expected: 全部浏览器冒烟通过。

Run: `.\\scripts\\ci\\browser-e2e.ps1`
Expected: 包含隐私中心在内的真实后端场景全部通过。

## 计划自审

- 设计中的页面、接口、认证下载、注销与撤销都有对应任务。
- 无 TBD/TODO/“类似上一步”等占位描述。
- 类型名与后端响应字段保持一致。
