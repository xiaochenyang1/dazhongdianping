# M5b4 Merchant Review Operations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成商户点评列表、商家回复、点评申诉与管理端申诉审核后端闭环，并让 C 端公开点评返回商家回复。

**Architecture:** 新增 `module/merchant/review` 独立领域，商户端只操作当前商户、当前区域和员工门店范围内的公开点评。回复直接公开，申诉进入统一审核中心 `biz_type=6`；审核通过隐藏点评并重算门店评分，审核驳回允许商户编辑后重提。

**Tech Stack:** Java 17、Spring Boot 3.3.5、MyBatis、H2/MySQL、JUnit 5、MockMvc、现有商户 RBAC、审核中心、点评聚合服务与搜索索引事件。

---

## 文件结构

- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/controller/MerchantReviewController.java` — `/api/b/v1/reviews`、回复和申诉 API。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/service/MerchantReviewService.java` — 权限、查询、回复、申诉状态机和事务编排。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/mapper/MerchantReviewMapper.java` — 点评经营 Mapper 契约。
- Create: `backend/src/main/resources/mapper/MerchantReviewMapper.xml` — H2/MySQL 兼容 SQL。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/model/MerchantReviewRow.java` — 商户点评列表行模型。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/model/ReviewMerchantReplyRow.java` — 商家回复行模型。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/model/MerchantReviewAppealRow.java` — 商户申诉行模型。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/model/request/MerchantReviewReplyRequest.java` — 回复请求。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/model/request/MerchantReviewAppealSaveRequest.java` — 申诉保存请求。
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantReviewControllerTest.java` — 商户列表、回复、申诉 API 契约。
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminMerchantReviewAppealAuditControllerTest.java` — 申诉审核通过/驳回/重提契约。
- Modify: `backend/src/main/resources/schema.sql`、`sql/mysql/01_schema.sql` — 新增 `review_merchant_reply`、`merchant_review_appeal`。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/model/response/ReviewDetailResponse.java` — 增加 `merchantReply`。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/service/ReviewService.java`、`backend/src/main/resources/mapper/ReviewMapper.xml` — 公开详情带商家回复，编辑/删除点评时失效申诉。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/browse/model/response/ReviewPreviewResponse.java`、`backend/src/main/java/com/tuowei/dazhongdianping/module/browse/service/BrowseQueryService.java`、`backend/src/main/resources/mapper/BrowseQueryMapper.xml` — 门店公开点评列表带商家回复。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`、`backend/src/main/resources/mapper/AdminAuditMapper.xml`、`backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/mapper/AdminAuditMapper.java` — 支持 `biz_type=6` 审核分派和摘要。
- Modify: `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/测试清单与验收用例.md`、`docs/当前已完成功能与SQL导入说明.md` — 回填 M5b4 状态。

---

### Task 1: 商户点评列表与回复 RED

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantReviewControllerTest.java`

- [ ] **Step 1: 写商户只能查询授权公开点评的失败测试**

```java
@Test
void shouldListOnlyPublicReviewsInMerchantShopScope() throws Exception {
    String ownerToken = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");

    mockMvc.perform(get("/api/b/v1/reviews")
                    .header("Authorization", bearer(ownerToken))
                    .header("X-Region", "EU")
                    .param("shopId", "20001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.list[0].shopId").value(20001))
            .andExpect(jsonPath("$.data.list[0].auditStatus").value(1))
            .andExpect(jsonPath("$.data.list[0].status").value(1));
}
```

- [ ] **Step 2: 写回复创建、编辑并公开展示的失败测试**

```java
Long reviewId = jdbc.queryForObject(
        "SELECT id FROM review WHERE shop_id=20001 AND region='EU' AND audit_status=1 AND status=1 AND is_deleted=FALSE ORDER BY id LIMIT 1",
        Long.class
);

mockMvc.perform(put("/api/b/v1/reviews/{reviewId}/reply", reviewId)
                .header("Authorization", bearer(ownerToken))
                .header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"感谢反馈，我们已经优化服务流程。\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.content").value("感谢反馈，我们已经优化服务流程。"));

mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId)
                .header("X-Region", "EU"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.merchantReply.content").value("感谢反馈，我们已经优化服务流程。"));
```

- [ ] **Step 3: 运行测试确认 RED**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=MerchantReviewControllerTest test
```

Expected: FAIL，原因是商户点评 API 与商家回复字段尚不存在。

---

### Task 2: 表结构、模型与回复 GREEN

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/**`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/**`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/browse/**`

- [ ] **Step 1: 新增 H2/MySQL 表**

```sql
CREATE TABLE IF NOT EXISTS review_merchant_reply (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    content VARCHAR(500) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_review_merchant_reply_review
    ON review_merchant_reply(review_id);
CREATE INDEX IF NOT EXISTS idx_review_merchant_reply_shop
    ON review_merchant_reply(shop_id, updated_at);

CREATE TABLE IF NOT EXISTS merchant_review_appeal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    review_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    base_review_updated_at TIMESTAMP NULL,
    reason VARCHAR(500) NOT NULL DEFAULT '',
    evidence_urls VARCHAR(2000) NOT NULL DEFAULT '[]',
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

MySQL 使用 `DATETIME ... ON UPDATE CURRENT_TIMESTAMP`，并增加唯一键 `uk_merchant_review_appeal(merchant_id, review_id)`、索引 `idx_merchant_review_appeal_status` 与 `idx_merchant_review_appeal_shop`。

- [ ] **Step 2: 定义请求模型**

```java
public record MerchantReviewReplyRequest(
        @NotBlank @Size(max = 500) String content
) {}

public record MerchantReviewAppealSaveRequest(
        @NotBlank @Size(min = 10, max = 500) String reason,
        @NotNull @Size(max = 6) List<@NotBlank @Size(max = 255) String> evidenceUrls
) {}
```

- [ ] **Step 3: 实现商户回复最小 GREEN**

```java
@Transactional
public Map<String, Object> saveReply(Long reviewId, MerchantReviewReplyRequest request) {
    MerchantSession session = merchant();
    MerchantReviewRow review = requirePublicReviewInScope(session, reviewId, "review:reply");
    String content = request.content().trim();
    ReviewMerchantReplyRow existing = mapper.selectReply(reviewId);
    if (existing == null) {
        mapper.insertReply(reviewId, review.getShopId(), session.merchantId(), session.operatorId(), content);
        mapper.insertOperationLog(session.merchantId(), session.operatorId(), "review_reply_create", "review", reviewId, content);
    } else {
        mapper.updateReply(reviewId, session.merchantId(), session.operatorId(), content);
        mapper.insertOperationLog(session.merchantId(), session.operatorId(), "review_reply_update", "review", reviewId, content);
    }
    return replyMap(mapper.selectReply(reviewId));
}
```

- [ ] **Step 4: 公开点评增加商家回复**

`ReviewDetailResponse` 增加可空 `MerchantReplyResponse merchantReply`；公开门店点评列表的 `ReviewPreviewResponse` 同步增加相同结构。C 端只读 `review_merchant_reply`，不返回申诉字段。

- [ ] **Step 5: 运行 Task 1 测试确认 GREEN**

Run: `backend\mvnw.cmd -Dtest=MerchantReviewControllerTest test`

Expected: 商户列表与回复公开展示用例 PASS。

---

### Task 3: 申诉草稿、保存和提交 RED/GREEN

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantReviewControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/review/service/MerchantReviewService.java`
- Modify: `backend/src/main/resources/mapper/MerchantReviewMapper.xml`

- [ ] **Step 1: 写申诉提交生成 `biz_type=6` 的失败测试**

```java
MvcResult draft = mockMvc.perform(post("/api/b/v1/reviews/{reviewId}/appeal-drafts", reviewId)
                .header("Authorization", bearer(ownerToken))
                .header("X-Region", "EU"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.status").value(0))
        .andReturn();
long appealId = objectMapper.readTree(draft.getResponse().getContentAsString()).at("/data/id").asLong();

mockMvc.perform(put("/api/b/v1/review-appeals/{appealId}", appealId)
                .header("Authorization", bearer(ownerToken))
                .header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "reason": "点评内容包含与实际消费无关的人身攻击，请平台复核。",
                          "evidenceUrls": ["https://files.example/order-proof.jpg"]
                        }
                        """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.status").value(0));

mockMvc.perform(post("/api/b/v1/review-appeals/{appealId}/submit", appealId)
                .header("Authorization", bearer(ownerToken))
                .header("X-Region", "EU"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.status").value(1));

assertEquals(1, jdbc.queryForObject(
        "SELECT COUNT(1) FROM audit_task WHERE biz_type=6 AND biz_id=? AND status=0",
        Integer.class,
        appealId
));
```

- [ ] **Step 2: 实现草稿复用、保存和提交**

```java
@Transactional
public Map<String, Object> submitAppeal(Long appealId) {
    MerchantSession session = merchant();
    MerchantReviewAppealRow appeal = editableAppeal(session, appealId, false);
    MerchantReviewRow review = requirePublicReviewInScope(session, appeal.getReviewId(), "review:appeal");
    validateAppealPayload(appeal.getReason(), parseEvidenceUrls(appeal.getEvidenceUrls()));
    if (mapper.submitAppeal(appealId, session.merchantId(), session.operatorId(), review.getUpdatedAt()) != 1) {
        throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
    }
    AuditTaskRow task = new AuditTaskRow();
    task.setBizType(6);
    task.setBizId(appealId);
    task.setRegion(region());
    task.setMachineResult(0);
    task.setStatus(0);
    task.setAuditorId(0L);
    task.setRemark("");
    adminAuditMapper.insertAuditTask(task);
    mapper.insertOperationLog(session.merchantId(), session.operatorId(), "review_appeal_submit", "review", appeal.getReviewId(), appeal.getReason());
    return appealMap(requireAppeal(session, appealId));
}
```

待审状态不允许编辑；驳回首次编辑时 `3 -> 0` 并清空旧审核字段；重复提交返回 `400`。

- [ ] **Step 3: 运行申诉测试确认 GREEN**

Run: `backend\mvnw.cmd -Dtest=MerchantReviewControllerTest test`

Expected: 商户列表、回复、申诉提交全部 PASS。

---

### Task 4: 管理端申诉审核 RED/GREEN

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminMerchantReviewAppealAuditControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/mapper/AdminAuditMapper.java`
- Modify: `backend/src/main/resources/mapper/AdminAuditMapper.xml`

- [ ] **Step 1: 写审核通过隐藏点评并重算评分的失败测试**

```java
mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                .header("Authorization", bearer(adminToken()))
                .header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"remark\":\"申诉成立\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.bizType").value(6));

mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId)
                .header("X-Region", "EU"))
        .andExpect(status().isNotFound());

assertEquals(2, jdbc.queryForObject(
        "SELECT status FROM merchant_review_appeal WHERE id=?",
        Integer.class,
        appealId
));
```

- [ ] **Step 2: 写驳回不隐藏且可重提的失败测试**

管理员驳回后断言点评仍公开、申诉 `status=3` 且 `reject_reason` 回显；商户保存新理由后状态回到 `0`，再次提交生成新的 `biz_type=6` 待审任务。

- [ ] **Step 3: 实现 `biz_type=6` 审核分派**

```java
private static final int REVIEW_APPEAL_BIZ_TYPE = 6;

if (task.getBizType() == REVIEW_APPEAL_BIZ_TYPE) {
    return passReviewAppealTask(task, request, requestIp);
}
```

`requirePendingTask` 允许 `6`；`bizTypeText` 返回 `商户点评申诉`；Mapper 摘要关联 `merchant_review_appeal`、`review`、`shop`、`merchant`。

- [ ] **Step 4: 实现通过与驳回事务**

通过：锁定申诉与点评，校验申诉待审、点评公开、版本一致；审核任务 `0 -> 1`；点评 `audit_status=2` 且 `audit_remark` 写入申诉通过原因；申诉 `1 -> 2`；处理待处理 `review_report`，失效该点评其他待审审核任务；重算门店评分并发布 `ShopSearchIndexChangedEvent`。

驳回：审核任务 `0 -> 2`；申诉 `1 -> 3`；点评保持公开，不重算评分、不发搜索事件。

- [ ] **Step 5: 运行审核测试确认 GREEN**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=MerchantReviewControllerTest,AdminMerchantReviewAppealAuditControllerTest test
```

Expected: PASS。

---

### Task 5: 版本协作、权限与回归

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantReviewControllerTest.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminMerchantReviewAppealAuditControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/review/service/ReviewService.java`

- [ ] **Step 1: 增加权限失败测试**

覆盖：核销员无 `review:reply/review:appeal` 返回 `401`；单店员工访问其他门店点评返回 `404`；跨区域或跨商户统一 `404`；非公开、待审、驳回、删除点评不进商户列表。

- [ ] **Step 2: 增加点评版本协作测试**

用户编辑点评时，活动商户申诉和 `biz_type=6` 待审任务失效；用户删除点评时同样失效；申诉提交后点评 `updated_at` 变化，管理员通过返回 `400`，点评不被隐藏。

- [ ] **Step 3: 在 `ReviewService` 中失效商户申诉**

```java
merchantReviewService.invalidateActiveAppealsForReview(reviewId, "点评已编辑");
adminAuditMapper.invalidatePendingAuditTasksByBiz(6, appealId, "点评已编辑");
```

实现时避免 `ReviewService` 与商户服务循环依赖，可把失效方法放在 `MerchantReviewMapper` 注入 `ReviewService`，或新增轻量协作组件；优先选择不引入循环依赖的 Mapper 调用。

- [ ] **Step 4: 运行相关回归**

Run:

```powershell
cd backend
.\mvnw.cmd -Dtest=ReviewControllerTest,PublicBrowseControllerTest,MerchantReviewControllerTest,AdminMerchantReviewAppealAuditControllerTest,AdminAuditServiceTest test
```

Expected: PASS。

---

### Task 6: 文档、全量验证与完成审计

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/需求文档.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/业务流程与状态机.md`
- Modify: `docs/测试清单与验收用例.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`

- [ ] **Step 1: 运行后端全量测试**

Run:

```powershell
cd backend
.\mvnw.cmd test
```

Expected: 全部 PASS，无失败和错误。

- [ ] **Step 2: 同步 M5b4 文档状态**

把 M5b4 从欠账改为“后端闭环完成”；保留 `merchant-web`、WebSocket 通知、管理端申诉专页和真实外部环境联调为未完成，不把它们误标完成。

- [ ] **Step 3: 扫描旧口径**

Run:

```powershell
rg -n "M5b4.*未完成|点评回复/申诉.*未完成|点评经营.*欠账" README.md docs -g "*.md" -g "!docs/superpowers/**"
```

Expected: 只剩 M5c/M5d 和外部环境类欠账，不再把 M5b4 后端列为未完成。

- [ ] **Step 4: 执行仓库门禁**

Run:

```powershell
.\scripts\ci\verify-all.ps1
```

Expected: 后端测试、Web 单测/构建、管理端构建和脚本契约全部通过，退出码 `0`。

## 计划自审

- 设计文档中的商户点评列表、回复、申诉草稿、申诉保存、提交、审核通过、审核驳回、公开端回复展示、版本协作、权限隔离、H2/MySQL schema 和文档回填均有对应任务。
- 新增生产代码前先写 MockMvc RED 测试，符合当前仓库既有测试风格。
- M5b4 计划只完成后端闭环；独立 `merchant-web`、WebSocket 通知和管理端专页仍作为后续 M5c/M5d，不偷摸扩大本计划。
- 无 `TBD`、`TODO` 或“以后再补”的占位步骤。
