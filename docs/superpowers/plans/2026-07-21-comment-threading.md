# Comment Threading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为点评评论和帖子评论补齐两层盖楼能力：支持回复顶级评论或楼中回复、列表按顶级评论分页返回并附带 replies、现有 Web/Flutter 客户端可展示和发起回复。

**Architecture:** 保持现有 `/comments` 路由不变，在评论创建请求增加可选 `replyTo`，数据库接入 `reply_to` 字段并在查询阶段按“顶级评论 + replies”组装响应。后端先落测试，再改 H2/MySQL/MyBatis 和服务层；前端仅做消费模型、嵌套展示和回复交互，不在本次顺手掺 `@`、通知聚合或评论删除。

**Tech Stack:** Spring Boot + MyBatis + H2/MySQL、Vue 3 + TypeScript、Flutter。

---

### Task 1: 点评评论盖楼后端

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/review/controller/ReviewControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/ReviewCommentRow.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/request/ReviewCommentCreateRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/response/ReviewCommentResponse.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/service/ReviewService.java`
- Modify: `backend/src/main/resources/mapper/ReviewMapper.xml`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`

- [ ] **Step 1: 写失败测试**

```java
mockMvc.perform(post("/api/c/v1/reviews/1/comments")
        .header("Authorization", bearer(userToken))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
                {
                  "content": "我来补一层回复",
                  "replyTo": %d
                }
                """.formatted(parentCommentId)))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.replyTo.id").value(parentCommentId))
    .andExpect(jsonPath("$.data.parentId").value(parentCommentId));

mockMvc.perform(get("/api/c/v1/reviews/1/comments")
        .param("page", "1")
        .param("pageSize", "10"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.list[0].replies[0].replyTo.id").value(parentCommentId));
```

- [ ] **Step 2: 跑点评评论测试，确认先红**

Run: `mvn -Dtest=ReviewControllerTest test`
Expected: FAIL，报 `replyTo`/`parentId`/`replies` 字段不存在或 SQL 不支持。

- [ ] **Step 3: 最小实现后端盖楼**

```java
private record CommentThreadTarget(Long parentId, ReviewCommentRef replyTo) {}

Long replyToId = request.getReplyTo() == null ? 0L : request.getReplyTo();
CommentThreadTarget target = resolveReviewCommentThread(reviewId, replyToId);
row.setReplyTo(replyToId);
```

```xml
INSERT INTO review_comment(review_id,user_id,user_name,content,reply_to,status,is_deleted)
VALUES(#{reviewId},#{userId},#{userName},#{content},#{replyTo},#{status},FALSE)
```

- [ ] **Step 4: 跑点评评论测试，确认转绿**

Run: `mvn -Dtest=ReviewControllerTest test`
Expected: PASS，点评评论新增回复和列表嵌套断言通过。

- [ ] **Step 5: 提交点评评论盖楼实现**

```bash
git add backend/src/test/java/com/tuowei/dazhongdianping/module/review/controller/ReviewControllerTest.java backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/ReviewCommentRow.java backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/request/ReviewCommentCreateRequest.java backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/response/ReviewCommentResponse.java backend/src/main/java/com/tuowei/dazhongdianping/module/review/service/ReviewService.java backend/src/main/resources/mapper/ReviewMapper.xml backend/src/main/resources/schema.sql sql/mysql/01_schema.sql
git commit -m "feat: add threaded review comments"
```

### Task 2: 帖子评论盖楼后端

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/PostCommentRow.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/request/PostCommentCreateRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/response/PostCommentResponse.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java`
- Modify: `backend/src/main/resources/mapper/CommunityMapper.xml`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`

- [ ] **Step 1: 写帖子评论失败测试**

```java
mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
        .header("Authorization", bearer(actorToken))
        .header("X-Region", "EU")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
                {
                  "content":"楼中回复",
                  "replyTo": %d
                }
                """.formatted(parentCommentId)))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.parentId").value(parentCommentId));
```

- [ ] **Step 2: 跑社区控制器测试，确认先红**

Run: `mvn -Dtest=CommunityControllerTest test`
Expected: FAIL，帖子评论响应和 SQL 还不支持盖楼。

- [ ] **Step 3: 最小实现帖子评论盖楼**

```java
PostCommentThreadTarget target = resolvePostCommentThread(postId, replyToId);
row.setReplyTo(replyToId);
communityMapper.insertPostComment(row);
```

```xml
SELECT id,post_id,user_id,user_name,content,reply_to,created_at
FROM post_comment
WHERE post_id=#{postId} AND status=1 AND is_deleted=FALSE
```

- [ ] **Step 4: 跑社区控制器测试，确认转绿**

Run: `mvn -Dtest=CommunityControllerTest test`
Expected: PASS，帖子评论列表按顶级评论返回且 replies 完整。

- [ ] **Step 5: 提交帖子评论盖楼实现**

```bash
git add backend/src/test/java/com/tuowei/dazhongdianping/module/community/controller/CommunityControllerTest.java backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/PostCommentRow.java backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/request/PostCommentCreateRequest.java backend/src/main/java/com/tuowei/dazhongdianping/module/community/model/response/PostCommentResponse.java backend/src/main/java/com/tuowei/dazhongdianping/module/community/service/CommunityService.java backend/src/main/resources/mapper/CommunityMapper.xml backend/src/main/resources/schema.sql sql/mysql/01_schema.sql
git commit -m "feat: add threaded post comments"
```

### Task 3: Web/Flutter 客户端跟进

**Files:**
- Modify: `web/src/types/review.ts`
- Modify: `web/src/types/community.ts`
- Modify: `web/src/services/review.ts`
- Modify: `web/src/views/ReviewDetailView.vue`
- Modify: `web/src/views/PostDetailView.vue`
- Modify: `app/lib/features/community/community_repository.dart`
- Modify: `app/lib/features/community/post_detail_screen.dart`
- Modify: `app/test/features/community/community_repository_test.dart`
- Modify: `app/test/features/community/community_screens_test.dart`

- [ ] **Step 1: 先补客户端失败测试**

```dart
expect(comments.single.replies.single.replyTo?.userName, '评论用户');
expect(api.body, {'content': '楼中回复', 'replyTo': 11});
```

- [ ] **Step 2: 跑 Flutter 社区测试，确认先红**

Run: `flutter test app/test/features/community/community_repository_test.dart app/test/features/community/community_screens_test.dart`
Expected: FAIL，模型和 UI 还没有 replies/replyTo。

- [ ] **Step 3: 最小实现客户端展示与回复**

```ts
export interface ReviewComment {
  id: number
  parentId: number
  replyTo?: ReviewCommentRef | null
  replies: ReviewComment[]
}
```

```dart
Future<CommunityComment> createComment(int postId, String content, {int? replyTo}) async =>
    CommunityComment.fromJson(await api.postJson('/api/c/v1/posts/$postId/comments', body: {
      'content': content,
      if (replyTo != null) 'replyTo': replyTo,
    }));
```

- [ ] **Step 4: 跑 Web/Flutter 受影响测试**

Run: `npm --prefix web run build`
Expected: PASS

Run: `flutter test app/test/features/community/community_repository_test.dart app/test/features/community/community_screens_test.dart`
Expected: PASS

- [ ] **Step 5: 提交客户端盖楼支持**

```bash
git add web/src/types/review.ts web/src/types/community.ts web/src/services/review.ts web/src/views/ReviewDetailView.vue web/src/views/PostDetailView.vue app/lib/features/community/community_repository.dart app/lib/features/community/post_detail_screen.dart app/test/features/community/community_repository_test.dart app/test/features/community/community_screens_test.dart
git commit -m "feat: support threaded comments in web and flutter"
```
