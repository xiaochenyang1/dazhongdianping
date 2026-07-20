# M5 Gap Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成独立商户工作台、管理端商户点评申诉专页和 PC Web 实时通知闭环。

**Architecture:** 商户端与管理端只组合既有 REST 能力；通知采用数据库持久化加 WebSocket 实时推送，REST 负责离线补偿。所有权限最终由后端校验。

**Tech Stack:** Java 17、Spring Boot 3、MyBatis、H2/MySQL、Vue 3、TypeScript、Vite、Vitest、WebSocket。

---

### Task 1: 商户端基础工程与会话

**Files:**
- Create: `merchant-web/package.json`
- Create: `merchant-web/src/lib/http.ts`
- Create: `merchant-web/src/composables/useMerchantSession.ts`
- Create: `merchant-web/src/router/index.ts`
- Create: `merchant-web/src/views/LoginView.vue`

- [x] 写会话与请求头测试，证明 token、`X-Region` 和 `Idempotency-Key` 能正确附加。
- [x] 创建 Vite/Vue 工程和登录路由，未登录访问工作台时跳转 `/login`。
- [x] 运行 `npm test` 与 `npm run build`，预期全部通过。

### Task 2: 商户端经营页面

**Files:**
- Create: `merchant-web/src/services/merchant.ts`
- Create: `merchant-web/src/layouts/MerchantLayout.vue`
- Create: `merchant-web/src/views/DashboardView.vue`
- Create: `merchant-web/src/views/ReservationsView.vue`
- Create: `merchant-web/src/views/DealsView.vue`
- Create: `merchant-web/src/views/OrdersView.vue`
- Create: `merchant-web/src/views/ShopsView.vue`
- Create: `merchant-web/src/views/ReviewsView.vue`

- [x] 为现有 `/api/b/v1` 接口建立强类型 service。
- [x] 实现概览、门店、预订、团购、订单、点评回复与申诉页面。
- [x] 每个变更动作成功后重新读取服务端数据，失败显示后端错误信息。
- [x] 运行 `npm test` 与 `npm run build`，预期全部通过。

### Task 3: 管理端商户申诉专页

**Files:**
- Modify: `admin-web/src/router/index.ts`
- Modify: `admin-web/src/services/admin.ts`
- Create: `admin-web/src/views/ReviewAppealAuditView.vue`

- [x] 固定以 `bizType=6` 查询审核任务。
- [x] 实现状态筛选、分页、通过和驳回操作。
- [x] 运行 `npm run build`，预期通过。

### Task 4: 通知持久化与 REST 接口

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/notification/**`
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/notification/**`

- [x] 先写通知列表、未读数、已读确认和越权测试并确认失败。
- [x] 新增 `user_notification` 表、mapper、service 和 controller。
- [x] 运行通知测试并确认通过。

### Task 5: WebSocket ticket 与实时推送

**Files:**
- Modify: `backend/pom.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/notification/websocket/**`
- Modify: `web/src/services/notification.ts`
- Create: `web/src/composables/useNotifications.ts`
- Modify: `web/src/components/AppHeader.vue`

- [x] 先写 ticket 过期、一次性消费、无效 ticket 和 ACK 所属校验测试并确认失败。
- [x] 加入 Spring WebSocket 依赖、ticket 服务、握手处理器和在线会话注册表。
- [x] 在用户侧接入未读角标、通知列表、重连和 ACK。
- [x] 运行后端测试、Web 单测和构建并确认通过。

### Task 6: 全量回归与文档回写

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/测试清单与验收用例.md`

- [x] 运行 `backend/mvnw.cmd test`。
- [x] 运行 `web npm test`、`web npm run build`。
- [x] 运行 `admin-web npm run build`。
- [x] 运行 `merchant-web npm test`、`merchant-web npm run build`。
- [x] 仅在所有结果有证据通过后，把 M5 三项改为已完成；M6/M7 和真实外部环境联调继续明确标为后续阶段。
