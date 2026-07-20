# M7 Official Circles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成区域化官方圈子的管理、成员关系、圈子发帖、Flutter 完整互动、PC Web 只读展示和隐私治理。

**Architecture:** 新增独立 `circle` 模块维护圈子资料与成员关系，现有 `post` 通过可空 `circle_id` 复用审核、互动和举报链路。公开读取严格按 `X-Region` 过滤，管理端维护官方圈子，Flutter 提供写操作，PC Web 保持只读。

**Tech Stack:** Java 17、Spring Boot、MyBatis、H2/MySQL、Vue 3、Vitest、Flutter、Dart、JUnit 5。

---

### Task 1: C 端圈子资料与成员关系后端闭环

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/circle/controller/CircleControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/controller/CircleController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/service/CircleService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/mapper/CircleMapper.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/model/CircleRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/model/CircleMemberRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/model/response/CircleResponse.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/model/response/CircleMembershipResponse.java`
- Create: `backend/src/main/resources/mapper/CircleMapper.xml`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/config/WebMvcConfig.java`

- [x] **Step 1: 写 C 端失败集成测试**

测试必须覆盖：当前区域列表/详情、跨区 404、游客 `joinedByCurrentUser=false`、成员列表、加入/退出幂等、成员计数、停用圈子拒绝加入、未登录写操作返回 401。

核心契约示例：

```java
mockMvc.perform(put("/api/c/v1/groups/{id}/membership", circleId)
        .header("Authorization", bearer(user.token()))
        .header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.joined").value(true))
    .andExpect(jsonPath("$.data.memberCount").value(1));
```

- [x] **Step 2: 运行测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=CircleControllerTest test
```

Expected: FAIL，原因是 `/api/c/v1/groups` 路由与 `circle` 表不存在。

- [x] **Step 3: 添加 H2/MySQL 表结构**

添加 `circle`、`circle_member` 和索引：

```sql
CREATE TABLE IF NOT EXISTS circle (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  region VARCHAR(8) NOT NULL,
  name VARCHAR(64) NOT NULL,
  description VARCHAR(500) NOT NULL DEFAULT '',
  cover_url VARCHAR(255) NOT NULL DEFAULT '',
  member_count INT NOT NULL DEFAULT 0,
  post_count INT NOT NULL DEFAULT 0,
  sort INT NOT NULL DEFAULT 0,
  status TINYINT NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT uk_circle_region_name UNIQUE(region, name)
);
CREATE TABLE IF NOT EXISTS circle_member (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  circle_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_circle_member UNIQUE(circle_id, user_id)
);
```

- [x] **Step 4: 实现最小 C 端 API**

Controller 路由固定为：

```java
@GetMapping("/groups")
@GetMapping("/groups/{id}")
@GetMapping("/groups/{id}/members")
@PutMapping("/groups/{id}/membership")
@DeleteMapping("/groups/{id}/membership")
```

`CircleService` 使用 `RegionContext.getRegion()` 过滤，加入时只在首次插入后增加 `member_count`，退出时只在实际删除后扣减并使用 `GREATEST(member_count - 1, 0)`。

- [x] **Step 5: 加入鉴权路径并重跑 GREEN**

在 `WebMvcConfig` 添加 `/api/c/v1/groups/**`，并在 `UserAuthInterceptor` 将 `GET /groups`、`GET /groups/{id}`、`GET /groups/{id}/members` 识别为公开读取。

Run:

```powershell
.\mvnw.cmd -Dtest=CircleControllerTest test
```

Expected: PASS，0 failures。

### Task 2: 圈子帖子复用现有社区链路

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/request/PostCreateRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/request/PostUpdateRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/PostRow.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/response/PostResponse.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/mapper/CommunityMapper.java`
- Modify: `backend/src/main/resources/mapper/CommunityMapper.xml`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/controller/CircleController.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/circle/service/CircleService.java`

- [x] **Step 1: 写圈子发帖失败测试**

覆盖：加入后发帖成功、未加入 409、跨区/停用圈子 404、圈子帖子列表只返回审核通过且公开的当前圈子帖子、响应包含 `circleId/circleName`、退出后历史帖子保留。

请求契约：

```json
{
  "circleId": 3001,
  "title": "伦敦周末探店",
  "content": "加入圈子后发布的真实帖子",
  "contentType": 1,
  "images": [],
  "topics": ["伦敦生活"]
}
```

- [x] **Step 2: 运行社区定向测试确认 RED**

```powershell
cd backend
.\mvnw.cmd -Dtest=CommunityControllerTest,CircleControllerTest test
```

Expected: FAIL，`circleId` 未进入请求、表和查询。

- [x] **Step 3: 扩展帖子模型和 SQL**

为 `post` 增加：

```sql
ALTER TABLE post ADD COLUMN circle_id BIGINT NULL;
CREATE INDEX idx_post_circle_status ON post(circle_id, audit_status, status, is_deleted, id);
```

所有帖子查询列统一增加 `p.circle_id` 和圈子名称 LEFT JOIN，避免列表与详情响应不一致。

- [x] **Step 4: 实现发帖资格校验和圈子帖子读取**

`CommunityService.create` 在 `circleId != null` 时调用圈子服务：

```java
circleService.requirePostingMembership(request.getCircleId(), currentUserId, region);
```

新增 `GET /api/c/v1/groups/{id}/posts`，内部复用社区公开帖子分页查询，不复制点赞、评论或举报逻辑。

- [x] **Step 5: 维护 `post_count` 并验证 GREEN**

在帖子首次审核通过、删除或下架时根据真实状态迁移增减 `post_count`；计数和帖子状态修改保持同一事务。

```powershell
.\mvnw.cmd -Dtest=CommunityControllerTest,CircleControllerTest test
```

Expected: PASS。

### Task 3: 管理端圈子维护

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/circle/AdminCircleControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/circle/AdminCircleController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/circle/AdminCircleService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/circle/model/CircleSaveRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/circle/model/CircleStatusRequest.java`
- Create: `admin-web/src/views/CircleManagementView.vue`
- Create: `admin-web/src/views/CircleManagementView.test.ts`
- Create: `admin-web/src/services/circle.ts`
- Modify: `admin-web/src/router/index.ts`
- Modify: `admin-web/src/layouts/AdminLayout.vue`

- [x] **Step 1: 写管理端后端失败测试**

覆盖当前管理员区域列表、创建、编辑、启停、排序、名称冲突 409、跨区不可见/不可修改。

- [x] **Step 2: 运行测试确认 RED**

```powershell
cd backend
.\mvnw.cmd -Dtest=AdminCircleControllerTest test
```

Expected: FAIL，管理端圈子路由不存在。

- [x] **Step 3: 实现管理端 API 并验证 GREEN**

请求模型：

```java
public record CircleSaveRequest(
    @NotBlank @Size(min = 2, max = 64) String name,
    @Size(max = 500) String description,
    @Size(max = 255) String coverUrl,
    Integer sort
) {}
```

Run: `.\mvnw.cmd -Dtest=AdminCircleControllerTest test`

Expected: PASS。

- [x] **Step 4: 写 Admin Web 失败测试**

测试页面加载、区域/状态筛选、创建编辑表单、启停确认和真实错误展示。

```powershell
cd admin-web
npm test -- CircleManagementView.test.ts
```

Expected: FAIL，页面和服务不存在。

- [x] **Step 5: 实现管理页面并验证**

页面只处理圈子资料与启停，不增加成员管理和帖子审核复制入口。

```powershell
npm test -- CircleManagementView.test.ts
npm run build
```

Expected: PASS，build exit code 0。

### Task 4: Flutter 圈子广场、详情和发帖入口

**Files:**
- Create: `app/lib/features/circle/circle_repository.dart`
- Create: `app/lib/features/circle/circle_square_screen.dart`
- Create: `app/lib/features/circle/circle_detail_screen.dart`
- Create: `app/lib/features/circle/circle_members_screen.dart`
- Create: `app/test/features/circle/circle_repository_test.dart`
- Create: `app/test/features/circle/circle_screens_test.dart`
- Modify: `app/lib/features/community/community_feed_screen.dart`
- Modify: `app/lib/features/community/community_repository.dart`
- Modify: `app/lib/features/community/post_editor_screen.dart`
- Modify: `app/lib/features/user/user_center_screen.dart`
- Modify: `app/lib/app.dart`

- [x] **Step 1: 写仓储失败测试**

覆盖列表、详情、成员、帖子、加入、退出和 `joined=true` 我的圈子查询；验证请求路径和 `circleId` 发帖载荷。

```dart
expect(api.path, '/api/c/v1/groups/3001/membership');
expect(api.lastBody?['circleId'], 3001);
```

- [x] **Step 2: 写 Widget 失败测试**

覆盖圈子广场、详情、成员数、帖子数、加入/退出乐观更新与失败恢复、游客登录引导、已加入用户打开编辑器、“我的圈子”入口。

- [x] **Step 3: 运行 Flutter RED**

```powershell
cd app
flutter test test/features/circle
```

Expected: FAIL，圈子仓储和页面不存在。

- [x] **Step 4: 实现仓储与页面**

圈子详情构造帖子编辑器时显式传递：

```dart
PostEditorScreen(
  repository: communityRepository,
  circleId: circle.id,
  circleName: circle.name,
)
```

游客点击加入/发帖只调用登录回调，不发受保护 API。加入/退出采用乐观状态，异常时恢复原成员数和状态。

- [x] **Step 5: 运行 Flutter GREEN 和 analyze**

```powershell
flutter test test/features/circle test/features/community
flutter analyze
```

Expected: All tests passed；No issues found。

### Task 5: PC Web 只读圈子展示

**Files:**
- Create: `web/src/views/CircleListView.vue`
- Create: `web/src/views/CircleDetailView.vue`
- Create: `web/src/views/CircleViews.test.ts`
- Create: `web/src/services/circle.ts`
- Modify: `web/src/router/index.ts`
- Modify: `web/src/views/CommunityView.vue`

- [x] **Step 1: 写只读页面失败测试**

覆盖圈子列表、详情、成员/帖子数字、帖子跳转、区域切换重新加载，并断言不存在“加入”“退出”“发帖”按钮。

```typescript
expect(wrapper.text()).not.toContain('加入圈子')
expect(wrapper.text()).not.toContain('发布帖子')
```

- [x] **Step 2: 运行 Web RED**

```powershell
cd web
npm test -- CircleViews.test.ts
```

Expected: FAIL，视图和服务不存在。

- [x] **Step 3: 实现只读服务、视图和路由**

路由使用 `/groups` 和 `/groups/:id`，详情帖子链接到现有 `/community/posts/:id`，作者链接到现有公开用户主页。

- [x] **Step 4: 运行 Web GREEN 和构建**

```powershell
npm test -- CircleViews.test.ts
npm run build
```

Expected: PASS，build exit code 0。

### Task 6: 隐私、注销、文档和全量验证

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/auth/controller/UserPrivacyControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/mapper/UserPrivacyMapper.java`
- Modify: `backend/src/main/resources/mapper/UserPrivacyMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/service/UserPrivacyService.java`
- Modify: `app/lib/features/user/privacy_overview_screen.dart`
- Modify: `app/test/features/user/privacy_overview_screen_test.dart`
- Modify: `README.md`
- Modify: `docs/需求文档.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`

- [x] **Step 1: 写 `circles` 隐私治理失败测试**

导出断言：

```java
assertJsonText(root, "/modules/circles/0/name", "伦敦生活圈");
```

注销断言：成员关系为 0，对应圈子 `member_count` 已扣减，历史圈子帖子仍按现有帖子规则匿名化。

- [x] **Step 2: 运行隐私测试确认 RED**

```powershell
cd backend
.\mvnw.cmd -Dtest=UserPrivacyControllerTest test
```

Expected: FAIL，`circles` 不在允许导出模块内。

- [x] **Step 3: 实现隐私导出和注销清理**

将 `circles` 加入 `ALLOWED_EXPORT_MODULES`，Mapper 返回本人加入圈子的 `id/name/region/joinedAt`。注销事务先按圈子分组扣减成员数，再删除 `circle_member`，最后沿用帖子匿名化。

- [x] **Step 4: 更新 Flutter 隐私中心和项目文档**

隐私中心默认勾选“圈子关系”，创建导出任务时发送 `circles`。文档必须明确 Flutter 可写、PC 只读、管理端维护和外部推送仍未完成。

- [x] **Step 5: 运行完整验证**

```powershell
.\scripts\ci\verify-all.ps1 -IncludeFlutter
```

Expected: exit code 0，最终输出 `all requested checks passed`。

- [x] **Step 6: 逐项审计规格验收标准**

核对管理端维护、Flutter 加入/发帖、现有帖子审核复用、CN/EU 隔离、PC 只读、隐私注销和全量 CI 七项均有实现与测试证据；发现缺口必须回到对应任务补测试再修复。

> 当前工作区没有有效 Git 元数据，计划中的提交步骤无法执行；不得伪造 commit。所有完成状态以测试和构建输出为准。
