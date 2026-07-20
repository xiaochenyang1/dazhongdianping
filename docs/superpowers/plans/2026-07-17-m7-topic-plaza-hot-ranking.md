# M7 Topic Plaza, Hot Ranking and Following Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 `topic/post_topic` 基础上完成区域化话题广场、7 天数据库快照热榜、话题关注、管理端治理、Flutter 完整互动、PC Web 只读展示和隐私治理。

**Architecture:** 新增独立 `topic` 领域模块负责公开查询、关注、合并治理和热榜快照；现有 `community` 模块继续持有帖子写入及互动，在帖子、点赞、评论和审核状态变化时刷新话题计数并通过 `topic.updated_at` 标记快照过期。热榜按区域在数据库内保存快照，定时任务每小时增量重算，首次读取无快照时同步兜底；Flutter 提供关注写操作，PC Web 保持只读。

**Tech Stack:** Java 17、Spring Boot 3.3、MyBatis、H2/MySQL、JUnit 5、Vue 3、TypeScript、Vitest、Flutter、Dart。

---

## 文件结构与职责

- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/controller/TopicController.java`：C 端话题列表、热榜、关注列表、详情、帖子与关注写接口。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicService.java`：区域隔离、公开状态校验、自动建档、合并目标解析、关注幂等和计数维护。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicHotRankingService.java`：7 天聚合、固定公式计算和无快照兜底。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicHotSnapshotWriter.java`：在独立事务边界内原子替换快照，失败时恢复旧数据。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/scheduler/TopicHotRankingScheduler.java`：CN/EU 每小时重算并按区域隔离失败。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/mapper/TopicMapper.java` 与 `backend/src/main/resources/mapper/TopicMapper.xml`：话题、关注、热榜、合并和帖子关联 SQL。
- `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/AdminTopicController.java` 与 `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/AdminTopicService.java`：管理端筛选、改名、推荐、置顶、屏蔽、合并和手动重算。
- `app/lib/features/topic/*`：Flutter 话题模型、仓储、三 Tab 广场和详情页。
- `web/src/services/topic.ts` 与 `web/src/views/Topic*View.vue`：PC Web 只读广场、热榜和详情。
- `admin-web/src/services/topic.ts` 与 `admin-web/src/views/TopicManagementView.vue`：运营治理页面。

### Task 1: C 端话题公开查询、自动创建和关注闭环

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/topic/controller/TopicControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/controller/TopicController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/mapper/TopicMapper.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/model/TopicRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/model/TopicHotSnapshotRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/model/response/TopicResponse.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/model/response/TopicFollowResponse.java`
- Create: `backend/src/main/resources/mapper/TopicMapper.xml`
- Delete: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/TopicRow.java`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/config/WebMvcConfig.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/UserAuthInterceptor.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/mapper/CommunityMapper.java`
- Modify: `backend/src/main/resources/mapper/CommunityMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`

- [x] **Step 1: 写 C 端和发帖关联失败测试**

`TopicControllerTest` 覆盖 CN/EU 列表隔离、游客读取、推荐/最新排序、详情、公开帖子、关注/取消关注幂等、`following` 登录要求、屏蔽/合并/跨区 404。`CommunityControllerTest` 增加自动建话题、请求内去重、最多 5 个、屏蔽名称 400、输入已合并名称自动落到最终目标和编辑时替换旧关联。

核心契约固定为：

```java
mockMvc.perform(put("/api/c/v1/topics/{id}/follow", topicId)
        .header("Authorization", bearer(user.token()))
        .header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.topicId").value(topicId))
    .andExpect(jsonPath("$.data.followed").value(true))
    .andExpect(jsonPath("$.data.followerCount").value(1));

mockMvc.perform(get("/api/c/v1/topics/{id}/posts", topicId)
        .header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.list[0].topics[0]").value("伦敦咖啡"));
```

- [x] **Step 2: 运行定向测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=TopicControllerTest,CommunityControllerTest test
```

Expected: FAIL，`/api/c/v1/topics` 路由、`topic_follow`、扩展字段和合并解析尚不存在；失败必须来自缺少功能，不能来自测试数据或 Spring 上下文错误。

- [x] **Step 3: 扩展 H2/MySQL 数据结构和领域模型**

把现有 `topic` 定义扩展为以下字段，并在两套 schema 中保持类型和索引一致：

```sql
CREATE TABLE topic (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  region VARCHAR(8) NOT NULL,
  name VARCHAR(64) NOT NULL,
  post_count INT NOT NULL DEFAULT 0,
  follower_count INT NOT NULL DEFAULT 0,
  recommended BOOLEAN NOT NULL DEFAULT FALSE,
  pinned_sort INT NOT NULL DEFAULT 0,
  merged_to_id BIGINT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_topic_region_name UNIQUE(region, name)
);

CREATE TABLE topic_follow (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  topic_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_topic_follow UNIQUE(topic_id, user_id)
);

CREATE INDEX idx_topic_follow_user ON topic_follow(user_id, created_at, id);

CREATE TABLE topic_hot_snapshot (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  topic_id BIGINT NOT NULL,
  region VARCHAR(8) NOT NULL,
  score BIGINT NOT NULL DEFAULT 0,
  post_count_7d INT NOT NULL DEFAULT 0,
  like_count_7d INT NOT NULL DEFAULT 0,
  comment_count_7d INT NOT NULL DEFAULT 0,
  calculated_at TIMESTAMP NOT NULL,
  CONSTRAINT uk_topic_hot_snapshot UNIQUE(topic_id)
);

CREATE INDEX idx_topic_hot_region_score
  ON topic_hot_snapshot(region, score, topic_id);
```

将 `TopicRow` 移到 `module.topic.model`，字段固定为 `id/region/name/postCount/followerCount/recommended/pinnedSort/mergedToId/status/createdAt/updatedAt`。`TopicResponse` 固定为：

```java
public record TopicResponse(
        Long id, String region, String name,
        Integer postCount, Integer followerCount,
        Boolean recommended, Integer pinnedSort,
        Boolean followedByCurrentUser,
        Long hotScore, Integer postCount7d,
        Integer likeCount7d, Integer commentCount7d,
        String calculatedAt
) {}
```

- [x] **Step 4: 实现公开 API、关注幂等和帖子话题解析**

Controller 路由固定为：

```java
@GetMapping("/topics")
@GetMapping("/topics/hot")
@GetMapping("/topics/following")
@GetMapping("/topics/{id}")
@GetMapping("/topics/{id}/posts")
@PutMapping("/topics/{id}/follow")
@DeleteMapping("/topics/{id}/follow")
```

`TopicService` 的规则必须落实为可复用方法：

```java
public List<Long> resolveTopicIdsForPost(List<String> rawNames) {
    LinkedHashSet<String> names = rawNames == null
            ? new LinkedHashSet<>()
            : rawNames.stream()
                .filter(StringUtils::hasText)
                .map(String::trim)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    return names.stream().limit(5).map(this::resolveOrCreateTopicId).toList();
}
```

`resolveOrCreateTopicId` 必须查询同区域全部状态：正常话题直接返回；`merged_to_id != null` 时循环解析到最终正常目标并设置最大跳转深度防御环；`status=2 AND merged_to_id IS NULL` 抛 `IllegalArgumentException("话题不可用")`；完全不存在才插入。并发唯一键冲突时捕获 `DuplicateKeyException` 后重新查询，不能制造 500。

关注使用唯一键保证幂等：首次插入后按真实行数刷新 `follower_count`，重复关注保持原计数；取消时只有实际删除才刷新。公开查询统一使用 `region=#{region} AND status=1 AND merged_to_id IS NULL`，`sort=recommended` 只返回 `recommended=TRUE` 并按 `pinned_sort DESC,id DESC`，`sort=latest` 按 `id DESC`。`following` 按 `topic_follow.created_at DESC,id DESC`。

`CommunityService.saveAssets` 改为调用 `topicService.resolveTopicIdsForPost(request.topics())`，逐个写入 `post_topic`；编辑前先保存旧话题 ID，删除旧关联后写入新关联，再刷新旧、新话题 `post_count` 和 `updated_at`。`CommunityMapper` 新增话题帖子分页，并沿用公开帖子条件 `audit_status=1 AND status=1 AND is_deleted=FALSE`。

`WebMvcConfig` 增加 `/api/c/v1/topics` 与 `/api/c/v1/topics/**`；`UserAuthInterceptor` 只放行以下 GET：

```java
uri.matches("^/api/c/v1/topics(?:/hot|/\\d+(?:/posts)?)?$")
```

因此 `/topics/following` 和 PUT/DELETE 仍强制登录。

- [x] **Step 5: 重跑后端测试确认 GREEN 并记录检查点**

Run:

```powershell
.\mvnw.cmd -Dtest=TopicControllerTest,CommunityControllerTest test
```

Expected: PASS，0 failures；测试日志能证明区域隔离、404/400/401、自动创建、合并重定向和关注计数均成立。

当前工作区没有有效 Git 元数据，此处不执行或伪造 commit；以定向测试输出作为 Task 1 检查点。

### Task 2: 7 天热度快照、定时重算和互动触发

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/topic/service/TopicHotRankingServiceTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicHotRankingService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicHotSnapshotWriter.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/scheduler/TopicHotRankingScheduler.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/model/TopicHotMetricRow.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/DazhongDianpingBackendApplication.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/mapper/TopicMapper.java`
- Modify: `backend/src/main/resources/mapper/TopicMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/service/TopicService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditServiceTest.java`

- [x] **Step 1: 写公式、窗口、排序和失败保留的失败测试**

测试构造固定相对时间：窗口内 2 篇公开帖子、3 次点赞、4 条有效评论，另插入 8 天前事件、待审核帖子、已删除帖子、隐藏评论作为排除样本。断言：

```java
assertThat(snapshot.getPostCount7d()).isEqualTo(2);
assertThat(snapshot.getLikeCount7d()).isEqualTo(3);
assertThat(snapshot.getCommentCount7d()).isEqualTo(4);
assertThat(snapshot.getScore()).isEqualTo(2L * 20 + 3L * 3 + 4L * 5 + 100);
```

同时覆盖 `pinned_sort > 0` 优先、普通项 `score DESC,follower_count DESC,id DESC`、屏蔽/已合并排除、CN/EU 不串区、首次无快照同步生成。先插入旧快照，再直接调用 `TopicHotSnapshotWriter.replaceTopics(Set.of(topicId), List.of(invalidSnapshot))`，其中 `invalidSnapshot.topicId=null`，用非空约束异常验证同一事务中先删除的旧 `topic_hot_snapshot` 已回滚恢复且数值未变。

- [x] **Step 2: 运行热榜测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=TopicHotRankingServiceTest,TopicControllerTest test
```

Expected: FAIL，热度聚合、快照替换和 `sort=hot` 尚未实现。

- [x] **Step 3: 实现聚合、快照替换和公开热榜读取**

窗口语义固定为：`post_count_7d` 统计窗口内创建的公开帖子；`like_count_7d` 和 `comment_count_7d` 统计窗口内发生、且所属帖子当前仍公开的互动。聚合 SQL 使用以下三个完整表达式避免多表 JOIN 放大计数：

```sql
COUNT(DISTINCT CASE WHEN p.created_at >= #{cutoff} THEN p.id END) AS post_count_7d,
COUNT(DISTINCT CASE WHEN pl.created_at >= #{cutoff} THEN pl.id END) AS like_count_7d,
COUNT(DISTINCT CASE WHEN pc.created_at >= #{cutoff}
                         AND pc.status = 1
                         AND pc.is_deleted = FALSE
                    THEN pc.id END) AS comment_count_7d
```

`TopicHotRankingService` 计算公式只能有一个实现：

```java
private long score(TopicHotMetricRow row) {
    return row.getPostCount7d() * 20L
            + row.getLikeCount7d() * 3L
            + row.getCommentCount7d() * 5L
            + (Boolean.TRUE.equals(row.getRecommended()) ? 100L : 0L);
}
```

`TopicHotRankingService.recalculateRegion(region)` 先完整聚合并构建新行，再调用 `TopicHotSnapshotWriter.replaceTopics(topicIds, snapshots)`。Writer 签名固定为 `public void replaceTopics(Set<Long> topicIds, List<TopicHotSnapshotRow> snapshots)`，方法标注 `@Transactional`，按 ID 删除待替换快照后逐行插入；任何异常使整个 Writer 事务回滚，从而保留旧快照。`ensureRegionSnapshot(region)` 仅在正常公开话题存在且该区域快照数为 0 时同步调用重算。

公开热榜 SQL 固定排序：

```sql
ORDER BY
  CASE WHEN t.pinned_sort > 0 THEN 0 ELSE 1 END,
  t.pinned_sort DESC,
  s.score DESC,
  t.follower_count DESC,
  t.id DESC
```

`GET /api/c/v1/topics/hot` 与 `GET /api/c/v1/topics?sort=hot` 共用同一查询和分页逻辑，返回 `hotScore/postCount7d/likeCount7d/commentCount7d/calculatedAt`。

- [x] **Step 4: 接入定时任务和所有状态变化触发点**

在应用入口增加 `@EnableScheduling`，Scheduler 固定为：

```java
@Scheduled(cron = "0 0 * * * *")
public void recalculateHourly() {
    for (String region : List.of("CN", "EU")) {
        try {
            hotRankingService.recalculateDirtyRegion(region);
        } catch (RuntimeException exception) {
            log.error("topic hot ranking recalculation failed, region={}", region, exception);
        }
    }
}
```

脏标记不新增伪缓存表：`TopicMapper.touchTopicsByPostId(postId)` 更新关联话题 `updated_at=CURRENT_TIMESTAMP`，`recalculateDirtyRegion` 只选择快照缺失或 `topic.updated_at > snapshot.calculated_at` 的话题。以下路径必须刷新 `post_count` 并 touch：发帖关联完成、编辑替换关联、帖子删除/重新提交、审核通过/驳回/下架。以下路径只 touch：点赞切换、评论创建。管理端推荐变更在 Task 3 中同步重算受影响话题。

- [x] **Step 5: 重跑热榜与社区测试确认 GREEN**

Run:

```powershell
.\mvnw.cmd -Dtest=TopicHotRankingServiceTest,TopicControllerTest,CommunityControllerTest,AdminAuditServiceTest test
```

Expected: PASS；快照失败测试证明旧榜单未被清空，窗口边界和固定权重断言精确通过。

当前工作区没有有效 Git 元数据，以测试输出作为 Task 2 检查点。

### Task 3: 管理端改名、推荐、置顶、屏蔽、合并和重算

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/topic/AdminTopicControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/AdminTopicController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/AdminTopicService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/model/TopicUpdateRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/model/TopicRecommendationRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/model/TopicStatusRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/model/TopicMergeRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/topic/model/response/AdminTopicResponse.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/topic/mapper/TopicMapper.java`
- Modify: `backend/src/main/resources/mapper/TopicMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/controller/AdminAuthController.java`
- Create: `admin-web/src/services/topic.ts`
- Create: `admin-web/src/views/TopicManagementView.vue`
- Create: `admin-web/src/views/TopicManagementView.test.ts`
- Modify: `admin-web/src/router/index.ts`

- [x] **Step 1: 写管理端后端失败测试**

覆盖区域/状态/推荐/关键词筛选、改名、409 名称冲突、推荐开关、`pinnedSort`、屏蔽、跨区 404、手动重算。合并测试必须构造源和目标都关联同一帖子、同一用户同时关注两者，断言迁移后 `post_topic` 与 `topic_follow` 均无重复，目标计数来自真实行数，源 `merged_to_id` 指向目标且 `status=2`，源快照删除、目标快照重算。

请求契约固定为：

```json
PUT /api/admin/v1/topics/31/recommendation
{"recommended":true,"pinnedSort":50}

POST /api/admin/v1/topics/31/merge
{"targetTopicId":32}
```

跨区域合并、合并自身、目标已合并返回 400；改名冲突返回 409。

- [x] **Step 2: 运行后端测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=AdminTopicControllerTest test
```

Expected: FAIL，管理端话题路由和合并事务尚不存在。

- [x] **Step 3: 实现管理 API 和原子合并事务并确认 GREEN**

Controller 路由固定为：

```java
@GetMapping("/api/admin/v1/topics")
@PutMapping("/api/admin/v1/topics/{id}")
@PutMapping("/api/admin/v1/topics/{id}/recommendation")
@PutMapping("/api/admin/v1/topics/{id}/status")
@PostMapping("/api/admin/v1/topics/{id}/merge")
@PostMapping("/api/admin/v1/topics/recalculate-hot")
```

请求模型固定约束：

```java
public record TopicUpdateRequest(@NotBlank @Size(max = 64) String name) {}
public record TopicRecommendationRequest(boolean recommended,
        @NotNull @Min(0) Integer pinnedSort) {}
public record TopicStatusRequest(@NotNull @Min(1) @Max(2) Integer status) {}
public record TopicMergeRequest(@NotNull @Positive Long targetTopicId) {}
```

`merge(sourceId,targetId)` 必须 `@Transactional` 并按顺序执行：使用 `SELECT id,region,name,merged_to_id,status FROM topic WHERE id=#{id} AND region=#{region} FOR UPDATE` 锁源和目标；校验当前 `X-Region`、非自身、两者未合并；先删除目标已存在的冲突 `post_topic`，再把剩余源关联更新到目标；对 `topic_follow` 做同样去重迁移；设置源 `merged_to_id=targetId,status=2,recommended=FALSE,pinned_sort=0`；按真实行数刷新目标 `post_count/follower_count`；删除源快照；同步重算目标快照。任何 SQL 或重算异常均回滚。

推荐变更后同步重算该话题分数；置顶只改变排序字段但仍 touch。屏蔽后公开 API 立即 404，旧快照可保留在事务内删除。后台列表返回 `status/mergedToId/hotScore/*Count7d/calculatedAt`。

管理菜单新增：

```java
new AdminMenuResponse("operations.topics", "话题治理", "/operations/topics", List.of())
```

Run: `.\mvnw.cmd -Dtest=AdminTopicControllerTest test`

Expected: PASS，0 failures。

- [x] **Step 4: 写 Admin Web 失败测试**

测试加载筛选、改名、推荐/取消推荐、置顶数字、屏蔽、手动重算、真实错误展示，以及合并二次确认文案同时包含源名称、目标名称和“不可逆”。

```typescript
expect(confirmText).toContain('将「伦敦咖啡」合并到「英国咖啡」')
expect(confirmText).toContain('不可逆')
expect(mocks.mergeTopic).toHaveBeenCalledWith(31, 32)
```

Run:

```powershell
cd admin-web
npm test -- TopicManagementView.test.ts
```

Expected: FAIL，服务、页面和路由尚不存在。

- [x] **Step 5: 实现管理页面并验证构建**

`admin-web/src/services/topic.ts` 导出 `listTopics/updateTopic/updateTopicRecommendation/updateTopicStatus/mergeTopic/recalculateTopicHot`。页面按当前会话区域读取，筛选参数固定为 `status/recommended/keyword/page/pageSize`；合并目标只能来自当前区域且未合并话题。所有失败显示后端消息，失败后不乐观改写列表。

Run:

```powershell
npm test -- TopicManagementView.test.ts
npm run build
```

Expected: 测试 PASS，build exit code 0。当前工作区没有有效 Git 元数据，以测试和构建输出作为 Task 3 检查点。

### Task 4: Flutter 话题广场、热榜、详情和关注

**Files:**
- Create: `app/lib/features/topic/topic_repository.dart`
- Create: `app/lib/features/topic/topic_plaza_screen.dart`
- Create: `app/lib/features/topic/topic_detail_screen.dart`
- Create: `app/test/features/topic/topic_repository_test.dart`
- Create: `app/test/features/topic/topic_screens_test.dart`
- Modify: `app/lib/features/community/community_feed_screen.dart`
- Modify: `app/lib/features/community/community_repository.dart`
- Modify: `app/test/features/community/community_repository_test.dart`
- Modify: `app/test/features/community/community_screens_test.dart`
- Modify: `app/lib/features/browse/home_screen.dart`
- Modify: `app/lib/app.dart`

- [x] **Step 1: 写 Flutter 仓储失败测试**

模型 `TopicSummary` 字段与后端 `TopicResponse` 一一对应。仓储方法固定为：

```dart
Future<List<TopicSummary>> loadRecommended()
Future<List<TopicSummary>> loadHot()
Future<List<TopicSummary>> loadFollowing()
Future<TopicSummary> loadDetail(int id)
Future<List<CommunityPost>> loadPosts(int id)
Future<TopicFollowState> follow(int id)
Future<TopicFollowState> unfollow(int id)
```

断言路径：

```dart
expect(api.path, '/api/c/v1/topics/hot');
expect(api.query?['pageSize'], 30);
expect(api.path, '/api/c/v1/topics/31/follow');
```

同时保留发帖回归：`CommunityRepository.savePost(topics: ['新话题'])` 的 JSON 仍包含原始话题名，不新增独立创建话题请求。

- [x] **Step 2: 写三 Tab、详情和乐观恢复失败测试**

Widget 测试覆盖“推荐/热榜/已关注”三个 Tab；游客切到“已关注”只显示登录引导且 API 调用次数为 0；热榜卡展示排名、热度分和“7 天帖子/点赞/评论”；详情展示关注人数、热度、公开帖子和作者入口。关注成功立即更新按钮和计数；API 抛错时恢复原状态并显示错误。

```dart
expect(find.text('热度 169'), findsOneWidget);
expect(find.text('7 天：2 帖 · 3 赞 · 4 评论'), findsOneWidget);
expect(fakeApi.followingCalls, 0);
```

- [x] **Step 3: 运行 Flutter RED**

Run:

```powershell
cd app
flutter test test/features/topic test/features/community
```

Expected: FAIL，`features/topic` 和社区页话题入口尚不存在。

- [x] **Step 4: 实现仓储、页面与应用接线**

`TopicPlazaScreen` 使用三个显式数据源，不把“已关注”伪装成帖子 Feed。游客切换第三个 Tab 时只渲染引导；点击关注时先保存 `followedByCurrentUser/followerCount` 原值并乐观更新，catch 中完整恢复。

`TopicDetailScreen` 复用 `CommunityPost` 展示帖子，点击帖子进入现有 `PostDetailScreen`；不提供独立话题创建表单。`CommunityFeedScreen` AppBar 增加“话题广场”入口，与现有“同城圈子”并列。`app.dart` 创建同一 `ApiClient` 上的 `TopicRepository` 并经 `HomeScreen` 传入；登录回调沿用现有 `onCommunityLoginRequired`。

发帖编辑器无需新增话题表单：现有话题字符串输入继续发送，后端自动建档。

- [x] **Step 5: 运行 Flutter GREEN、analyze 和 Web 构建**

Run:

```powershell
flutter test test/features/topic test/features/community test/features/browse
flutter analyze
flutter build web
```

Expected: All tests passed；`No issues found`；Flutter Web build exit code 0。当前工作区没有有效 Git 元数据，以三项输出作为 Task 4 检查点。

### Task 5: PC Web 只读话题广场、热榜和详情

**Files:**
- Create: `web/src/services/topic.ts`
- Create: `web/src/views/TopicListView.vue`
- Create: `web/src/views/TopicDetailView.vue`
- Create: `web/src/views/TopicViews.test.ts`
- Modify: `web/src/router/index.ts`
- Modify: `web/src/views/CommunityView.vue`

- [x] **Step 1: 写 PC Web 只读失败测试**

测试推荐列表、热榜排名与构成、详情公开帖子、帖子链接 `/community/posts/:id`、作者链接 `/users/:id`，并断言不存在“关注话题”“取消关注”“创建话题”“发布帖子”。

```typescript
expect(host.textContent).toContain('热度 169')
expect(host.textContent).toContain('2 帖 · 3 赞 · 4 评论')
expect(host.textContent).not.toContain('关注话题')
expect(host.textContent).not.toContain('发布帖子')
```

- [x] **Step 2: 运行 Web RED**

Run:

```powershell
cd web
npm test -- TopicViews.test.ts
```

Expected: FAIL，服务和视图尚不存在。

- [x] **Step 3: 实现只读服务、视图、路由和 SEO**

`web/src/services/topic.ts` 只导出 GET：

```typescript
fetchTopics(sort: 'recommended' | 'hot' | 'latest')
fetchHotTopics()
fetchTopic(id: number)
fetchTopicPosts(id: number)
```

路由固定为：

```typescript
{ path: '/topics', name: 'topic-list', component: () => import('@/views/TopicListView.vue'), meta: { title: '话题广场', description: '浏览当前区域推荐话题与最近 7 天热榜。' } }
{ path: '/topics/:id', name: 'topic-detail', component: () => import('@/views/TopicDetailView.vue'), props: r => ({ topicId: Number(r.params.id) }), meta: { title: '话题详情', description: '查看话题热度构成和公开社区帖子。' } }
```

`CommunityView.vue` 增加 `/topics` 入口。页面不引入 PUT/DELETE 客户端方法；SEO 继续复用 router `afterEach` 更新 title 和 description。

- [x] **Step 4: 运行 Web GREEN 和构建**

Run:

```powershell
npm test -- TopicViews.test.ts CommunityView.test.ts
npm run build
```

Expected: PASS，build exit code 0；产物中没有关注或发帖控件。当前工作区没有有效 Git 元数据，以测试和构建输出作为 Task 5 检查点。

### Task 6: `topics` 隐私治理、文档同步和全量验收

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/auth/model/TopicFollowExportRow.java`
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
- Modify: `docs/测试清单与验收用例.md`

- [x] **Step 1: 写隐私导出和注销清理失败测试**

导出任务选择 `topics` 后，解压 JSON 并断言：

```java
assertJsonText(root, "/modules/topics/0/name", "伦敦咖啡");
assertJsonText(root, "/modules/topics/0/region", "EU");
assertJsonText(root, "/modules/topics/0/followedAt", "2026-07-17 10:00:00");
```

注销测试构造用户关注两个话题，其中一个还有其他关注者；处理到期删除任务后断言本人 `topic_follow` 为 0、两个话题 `follower_count` 均等于实际剩余行数、`post_topic` 未删除、`topic_hot_snapshot` 未按用户清理。

- [x] **Step 2: 运行隐私测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=UserPrivacyControllerTest test
```

Expected: FAIL，`topics` 尚未加入允许导出模块且注销未清理话题关注。

- [x] **Step 3: 实现 `topics` 导出和按真实关系重算注销计数**

将 `topics` 加入 `ALLOWED_EXPORT_MODULES`。`TopicFollowExportRow` 字段固定为 `id/name/region/followedAt`，Mapper 查询按 `topic_follow.id DESC`。

注销事务顺序固定为：

```java
List<Long> topicIds = userPrivacyMapper.selectFollowedTopicIdsByUserId(userId);
userPrivacyMapper.deleteTopicFollowsByUserId(userId);
for (Long topicId : topicIds) {
    userPrivacyMapper.refreshTopicFollowerCount(topicId);
}
```

`refreshTopicFollowerCount` 使用 `SELECT COUNT(1) FROM topic_follow` 回填，不能简单 `-1`，这样即使历史冗余计数已漂移也能修正。帖子与话题关联、热榜快照保持不动。

- [x] **Step 4: 更新 Flutter 隐私中心和文档**

Flutter 隐私中心新增默认选中的“话题关注”选项，创建导出任务时在 `circles` 后发送 `topics`；说明文字改为“帖子、关注关系、私信、圈子和话题关注均支持真实导出”。同步文档内容：

- C 端全部话题 API、错误码和区域约束。
- `topic/topic_follow/topic_hot_snapshot` 字段、唯一键和索引。
- 7 天公式、置顶排序、每小时任务、首次读取兜底和失败保留旧快照。
- Flutter 可关注，PC Web 只读，管理端合并不可逆。
- 不存在独立话题 Feed、话题更新通知或 Redis 热榜依赖。

- [x] **Step 5: 运行隐私、三端定向回归**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=UserPrivacyControllerTest,TopicControllerTest,TopicHotRankingServiceTest,AdminTopicControllerTest test
cd ..\app
flutter test test/features/topic test/features/user/privacy_overview_screen_test.dart
cd ..\web
npm test -- TopicViews.test.ts
cd ..\admin-web
npm test -- TopicManagementView.test.ts
```

Expected: 所有定向测试 PASS。

- [x] **Step 6: 运行完整验证并逐项审计验收标准**

Run:

```powershell
cd E:\tuowei\python\dazhongdianping
.\scripts\ci\verify-all.ps1 -IncludeFlutter
```

Expected: exit code 0，最终输出 `all requested checks passed`；Flutter 测试、`flutter analyze`、Flutter Web 构建、后端测试、Web/Admin Web 测试与构建全部通过。

逐项保留证据：自动建档与屏蔽拒绝、7 天公式和置顶排序、关注幂等、“已关注”列表、管理端合并去重、CN/EU 隔离、PC 只读、`topics` 导出与注销清理。任一项缺证据都必须回到对应任务先补失败测试再修复。

> 当前工作区存在 `.git` 目录但没有可用 Git 元数据，无法安全执行 worktree、commit 或常规 `git status`。不得伪造提交记录；所有完成状态以 RED/GREEN 测试、构建和最终 CI 输出为准。
