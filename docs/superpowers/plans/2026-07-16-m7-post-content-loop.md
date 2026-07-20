# M7 Post Content Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成帖子发布、审核、公开流、互动、Flutter 完整入口、PC 只读展示和帖子隐私导出的第一条 M7 纵向闭环。

**Architecture:** 后端新增独立 `community` 模块并复用 `audit_task.biz_type=4`；帖子收藏复用 `user_favorite.target_type=2`。Flutter 通过仓储层调用 API，PC Web 只读，管理端复用审核中心交互。

**Tech Stack:** Java 17、Spring Boot、MyBatis、H2/MySQL、Vue 3、Flutter、JUnit/MockMvc、Vitest、flutter_test。

---

### Task 1: 帖子数据模型与发布审核主链路

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/**`
- Create: `backend/src/main/resources/mapper/CommunityMapper.xml`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`

- [ ] 编写失败测试：发布帖子后本人可见但公开列表和详情不可见。
- [ ] 运行定向测试并确认因社区接口不存在而失败。
- [ ] 新增帖子、图片、话题关联、点赞、评论、举报表及 Mapper。
- [ ] 实现发布、本人列表/详情、公开列表/详情和 `biz_type=4` 审核任务创建。
- [ ] 增加管理端帖子审核通过/驳回接口，使通过后公开、驳回后返回原因。
- [ ] 运行定向测试并确认通过。

### Task 2: 帖子编辑、删除与互动

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/**`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/favorite/**`
- Modify: `backend/src/main/resources/mapper/FavoriteMapper.xml`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/favorite/controller/FavoriteControllerTest.java`

- [ ] 编写失败测试：作者编辑重提、删除、点赞切换、评论、举报和帖子收藏。
- [ ] 运行定向测试并确认预期失败。
- [ ] 实现对应接口、作者/区域/公开状态校验与计数更新。
- [ ] 补齐收藏服务对 `target_type=2` 的目标查询和列表映射。
- [ ] 运行定向测试并确认通过。

### Task 3: 帖子隐私导出与注销治理

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/service/UserPrivacyService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/mapper/UserPrivacyMapper.java`
- Modify: `backend/src/main/resources/mapper/UserPrivacyMapper.xml`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/auth/controller/UserPrivacyControllerTest.java`

- [ ] 编写失败测试：导出 ZIP 的 `posts.json` 包含本人帖子，注销到期后作者信息匿名化。
- [ ] 运行定向测试并确认预期失败。
- [ ] 实现帖子导出和注销治理，不新增空的 `messages.json`。
- [ ] 运行定向测试并确认通过。

### Task 4: Flutter 社区仓储与页面

**Files:**
- Create: `app/lib/features/community/community_repository.dart`
- Create: `app/lib/features/community/community_feed_screen.dart`
- Create: `app/lib/features/community/post_editor_screen.dart`
- Create: `app/lib/features/community/post_detail_screen.dart`
- Modify: `app/lib/features/browse/home_screen.dart`
- Modify: `app/lib/features/user/user_repository.dart`
- Modify: `app/lib/features/user/user_collection_screen.dart`
- Test: `app/test/features/community/**`

- [ ] 编写失败仓储测试：列表、本人详情、发布、编辑、点赞、评论、举报。
- [ ] 实现最小仓储模型与 API 映射并跑绿。
- [ ] 编写失败 Widget 测试：公共流、发布图片、详情互动、本人编辑。
- [ ] 实现页面并接入首页社区入口和“我的帖子”。
- [ ] 运行 Flutter 定向测试并确认通过。

### Task 5: PC Web 只读社区

**Files:**
- Create: `web/src/types/community.ts`
- Create: `web/src/services/community.ts`
- Create: `web/src/views/CommunityView.vue`
- Create: `web/src/views/PostDetailView.vue`
- Modify: `web/src/router/index.ts`
- Test: `web/src/services/community.test.ts`
- Test: `web/src/views/CommunityView.test.ts`

- [ ] 编写失败测试：只读列表、详情和 APP 引导，页面不包含写帖/点赞/私信操作。
- [ ] 实现服务、类型、路由和页面。
- [ ] 运行 Web 定向测试并确认通过。

### Task 6: 管理端帖子审核

**Files:**
- Modify: `admin-web/src/services/**`
- Create: `admin-web/src/views/PostAuditView.vue`
- Modify: `admin-web/src/router/**`
- Test: `admin-web/src/**/PostAuditView.test.ts`

- [ ] 编写失败测试：展示待审帖子并提交通过/驳回。
- [ ] 实现管理端审核页面与 API 适配。
- [ ] 运行管理端定向测试并确认通过。

### Task 7: 文档与全量验证

**Files:**
- Modify: `README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/需求文档.md`
- Modify: `docs/接口设计.md`

- [ ] 同步 M7 第一阶段已完成和仍未完成边界。
- [ ] 运行后端全量测试。
- [ ] 运行 Web、管理端测试与构建。
- [ ] 运行 Flutter 全量测试、静态分析和 Web 构建。
- [ ] 逐项审计设计范围，不把关注、私信、圈子或真实推送写成已完成。

