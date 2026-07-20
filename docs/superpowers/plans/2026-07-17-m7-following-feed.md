# M7 Following Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 完成全局关注关系、按区域过滤的关注流、全局站内通知、Flutter 社交入口、PC 只读关系展示和隐私治理。

**Architecture:** 新增独立 `social` 后端模块维护全局用户关系；`community` 只负责将关注关系连接到当前区域的公开帖子。通知表以 `GLOBAL` 和 `actor_user_id` 支持跨区可见与注销治理，前端复用现有公开用户主页和社区页面扩展关系展示。

**Tech Stack:** Java 17、Spring Boot、MyBatis、H2/MySQL、Vue 3、TypeScript、Vitest、Flutter、Dart、JUnit 5、MockMvc。

---

### Task 1: 关注关系数据模型与后端接口

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/social/**`
- Create: `backend/src/main/resources/mapper/SocialMapper.xml`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/social/controller/SocialControllerTest.java`

- [x] **Step 1: 写失败测试**：覆盖关注、重复关注、取关、重复取关、自关注、目标不存在、粉丝/关注列表和跨区关系。
- [x] **Step 2: 运行测试并确认因 social API 不存在而失败**：`backend\\mvnw.cmd -f backend\\pom.xml -Dtest=SocialControllerTest test`。
- [x] **Step 3: 添加 `user_follow` 表、行模型、Mapper、Service、Controller 和响应模型**，实现显式幂等 `PUT/DELETE`，分页最大 50。
- [x] **Step 4: 重跑定向测试并确保通过**。

### Task 2: 关注流与公开用户统计

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/controller/CommunityController.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/mapper/CommunityMapper.java`
- Modify: `backend/src/main/resources/mapper/CommunityMapper.xml`
- Modify: existing public user profile controller/service/response files located by repository search
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`
- Test: relevant auth public-profile controller test

- [x] **Step 1: 写失败测试**：关注流仅返回当前区域、审核通过、正常且未删除的被关注者帖子；公开主页返回 `followerCount/followingCount/followedByCurrentUser`。
- [x] **Step 2: 运行定向测试并确认缺少字段/API 的预期失败**。
- [x] **Step 3: 实现 `/posts/following` 查询与公开主页统计扩展**。
- [x] **Step 4: 重跑定向测试并确保通过**。

### Task 3: GLOBAL 通知与注销治理

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/notification/**`
- Modify: `backend/src/main/resources/mapper/NotificationMapper.xml`
- Modify: privacy export/delete service and mapper files located by repository search
- Test: notification and privacy controller/service tests

- [x] **Step 1: 写失败测试**：首次关注只生成一条通知、GLOBAL 两区可见且已读共享、重复关注不重复通知、导出包含 `follows.json`、注销清理关系并匿名化来源通知。
- [x] **Step 2: 运行定向测试确认失败原因正确**。
- [x] **Step 3: 增加 `actor_user_id`、GLOBAL 查询语义、全区域 WebSocket 发送、关注通知和隐私治理实现**。
- [x] **Step 4: 重跑通知与隐私测试并确保通过**。

### Task 4: Flutter 关注流与公开用户主页

**Files:**
- Modify: `app/lib/features/community/community_repository.dart`
- Modify: `app/lib/features/community/community_feed_screen.dart`
- Modify: `app/lib/features/community/post_detail_screen.dart`
- Create/Modify: Flutter public-user profile repository/screens and routes
- Modify: notification screen routing
- Test: corresponding files under `app/test/features/community`, `app/test/features/user`, `app/test/features/notification`

- [x] **Step 1: 写失败测试**：双 Tab、游客登录引导、关注按钮与计数、关系列表、作者跳转、关注通知跳转。
- [x] **Step 2: 运行 Flutter 定向测试并确认失败**。
- [x] **Step 3: 实现仓储模型、页面状态和路由，失败时恢复乐观更新前状态**。
- [x] **Step 4: 重跑 Flutter 定向测试并确保通过**。

### Task 5: PC Web 只读关系展示

**Files:**
- Modify: `web/src/types/auth.ts`
- Modify: `web/src/services/auth.ts`
- Modify: `web/src/views/PublicUserProfileView.vue`
- Modify: `web/src/views/CommunityView.vue`
- Modify: `web/src/views/PostDetailView.vue`
- Test: relevant Vitest files

- [x] **Step 1: 写失败测试**：公开主页展示计数和只读列表，社区作者可进入主页，页面不存在关注/取关控件。
- [x] **Step 2: 运行 Vitest 定向测试并确认失败**。
- [x] **Step 3: 实现只读关系展示和作者链接**。
- [x] **Step 4: 重跑 Web 测试并确保通过**。

### Task 6: 文档与全量验证

**Files:**
- Modify: `README.md`
- Modify: `docs/需求文档.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/测试清单与验收用例.md`

- [x] **Step 1: 运行后端、Web、管理端、商户端和 Flutter 全量测试与构建**：`.\\scripts\\ci\\verify-all.ps1 -IncludeFlutter`。
- [x] **Step 2: 修复所有回归并重复验证，直到全绿**。
- [x] **Step 3: 按实际输出更新测试数量和完成边界；私信、圈子、真实 FCM/APNs 继续明确为未完成**。
- [x] **Step 4: 审计设计稿第 11 节每条验收项均有直接代码或测试证据**。

## 计划自审

- 已覆盖设计稿后端、通知、Flutter、PC Web、隐私与注销全部范围。
- 没有把私信、圈子、算法推荐或真实移动推送偷塞进本计划。
- 每个生产行为均要求先出现对应失败测试，再写实现。

