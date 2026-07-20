# M5b3 Merchant Shop Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成商户门店基础资料、相册和菜单的完整草稿审核闭环，审核通过前不影响线上数据。

**Architecture:** 新增 `merchant/shop` 独立领域模块和三张变更快照表。商户端维护完整候选快照并提交 `biz_type=5` 审核任务；管理端通过后在单事务内创建或替换 `shop/shop_photo/dish`，保留评分、点评数和团购聚合字段，并在事务提交后同步 Elasticsearch。

**Tech Stack:** Java 17、Spring Boot 3.3.5、MyBatis、H2/MySQL、JUnit 5、MockMvc、Jackson、现有审核中心与搜索索引事件。

---

## 文件结构

- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/controller/MerchantShopChangeController.java` — 商户草稿 API。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/service/MerchantShopChangeService.java` — 权限、校验、状态机和事务编排。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/mapper/MerchantShopChangeMapper.java` — 草稿、线上门店、相册和菜单 Mapper 契约。
- Create: `backend/src/main/resources/mapper/MerchantShopChangeMapper.xml` — H2/MySQL 兼容 SQL。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/ShopChangeRow.java` — 草稿行模型。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/ShopChangePhotoRow.java` — 候选照片。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/ShopChangeDishRow.java` — 候选菜品。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/request/ShopChangeSaveRequest.java` — 基础资料请求。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/request/ShopChangePhotoRequest.java` — 照片请求。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/request/ShopChangeDishRequest.java` — 菜品请求。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/request/ShopChangePhotosRequest.java` — 相册快照请求。
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/model/request/ShopChangeDishesRequest.java` — 菜单快照请求。
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantShopChangeControllerTest.java` — 商户草稿和提交契约。
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminShopChangeAuditControllerTest.java` — 新建、修改、驳回和版本冲突审核。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java` — 分派 `biz_type=5`。
- Modify: `backend/src/main/resources/mapper/AdminAuditMapper.xml` — 门店变更审核摘要。
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/mapper/AdminAuditMapper.java` — 审核申请状态更新方法。
- Modify: `backend/src/main/resources/schema.sql`、`sql/mysql/01_schema.sql` — 三张快照表及照片/菜品自增主键。
- Modify: `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/测试清单与验收用例.md`、`docs/当前已完成功能与SQL导入说明.md` — 回填 M5b3 状态。

---

### Task 1: 商户草稿契约 RED

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantShopChangeControllerTest.java`

- [ ] **Step 1: 写修改门店草稿不影响线上数据的失败测试**

```java
@Test
void shouldKeepLiveShopUnchangedUntilDraftIsApproved() throws Exception {
    String token = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");

    MvcResult created = mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                    .header("Authorization", bearer(token))
                    .header("X-Region", "EU"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.changeType").value(2))
            .andExpect(jsonPath("$.data.status").value(0))
            .andReturn();
    long changeId = json(created, "/data/id").asLong();

    mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                    .header("Authorization", bearer(token))
                    .header("X-Region", "EU")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(shopBody("Maison Sichuan Draft", "https://files.example/new-cover.jpg")))
            .andExpect(status().isOk());

    mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                    .header("Authorization", bearer(token))
                    .header("X-Region", "EU")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {"photos":[
                              {"imageUrl":"https://files.example/new-cover.jpg","photoType":1,"sort":1}
                            ]}
                            """))
            .andExpect(status().isOk());

    mockMvc.perform(get("/api/c/v1/shops/20001").header("X-Region", "EU"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.name").value("Maison Sichuan Paris"));
}
```

- [ ] **Step 2: 写菜单、提交、重复草稿和门店范围失败测试**

```java
mockMvc.perform(put("/api/b/v1/shop-changes/{id}/dishes", changeId)
        .header("Authorization", bearer(token))
        .header("X-Region", "EU")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
                {"dishes":[
                  {"name":"水煮鱼","price":28.00,"recommendReason":"招牌","sort":1}
                ]}
                """))
    .andExpect(status().isOk());

mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
        .header("Authorization", bearer(token))
        .header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.status").value(1));

assertEquals(1, jdbc.queryForObject(
        "SELECT COUNT(1) FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=0",
        Integer.class,
        changeId
));
```

同一门店再次创建草稿应返回已有申请；只授权 `shopId=20001` 的店长访问 `20002` 返回 `404`；缺少 `shop:edit` 返回 `401`。

- [ ] **Step 3: 运行测试确认 RED**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=MerchantShopChangeControllerTest test
```

Expected: FAIL，原因是 `/api/b/v1/shop-changes` 与草稿表尚不存在。

---

### Task 2: 草稿表、模型与商户 API GREEN

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/**`
- Create: `backend/src/main/resources/mapper/MerchantShopChangeMapper.xml`

- [ ] **Step 1: 同步 H2/MySQL 快照表**

H2：

```sql
CREATE TABLE IF NOT EXISTS merchant_shop_change (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    change_type TINYINT NOT NULL,
    target_shop_id BIGINT NOT NULL DEFAULT 0,
    base_updated_at TIMESTAMP NULL,
    category_id BIGINT NOT NULL DEFAULT 0,
    city_id BIGINT NOT NULL DEFAULT 0,
    area_id BIGINT NOT NULL DEFAULT 0,
    name VARCHAR(128) NOT NULL DEFAULT '',
    cover_url VARCHAR(255) NOT NULL DEFAULT '',
    phone VARCHAR(64) NOT NULL DEFAULT '',
    price_per_capita DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'CNY',
    address VARCHAR(255) NOT NULL DEFAULT '',
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    business_hours VARCHAR(128) NOT NULL DEFAULT '',
    summary VARCHAR(255) NOT NULL DEFAULT '',
    open_now BOOLEAN NOT NULL DEFAULT TRUE,
    tags VARCHAR(255) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS merchant_shop_change_photo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    change_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    photo_type TINYINT NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS merchant_shop_change_dish (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    change_id BIGINT NOT NULL,
    name VARCHAR(64) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    recommend_reason VARCHAR(255) NOT NULL DEFAULT '',
    sort_no INT NOT NULL DEFAULT 0
);
```

MySQL 使用等价字段、索引 `idx_shop_change_merchant_status`、`idx_shop_change_target_status`，并将 `shop_photo.id`、`dish.id` 改为 `AUTO_INCREMENT`。

- [ ] **Step 2: 定义请求模型**

```java
public record ShopChangePhotoRequest(
        @NotBlank @Size(max = 255) String imageUrl,
        @NotNull @Min(1) @Max(3) Integer photoType,
        @NotNull @Min(0) Integer sort
) {}

public record ShopChangeDishRequest(
        @NotBlank @Size(max = 64) String name,
        @NotNull @DecimalMin("0.00") BigDecimal price,
        @Size(max = 255) String recommendReason,
        @NotNull @Min(0) Integer sort
) {}

public record ShopChangePhotosRequest(
        @NotNull @Size(min = 1, max = 20) List<@Valid ShopChangePhotoRequest> photos
) {}

public record ShopChangeDishesRequest(
        @NotNull @Size(max = 100) List<@Valid ShopChangeDishRequest> dishes
) {}
```

`ShopChangeSaveRequest` 定义并校验规格中的全部商户可编辑字段；不包含评分、点评数、`hasDeal`、`merchantId` 或 `region`。

- [ ] **Step 3: 定义控制器契约**

```java
@RestController
@RequestMapping("/api/b/v1")
public class MerchantShopChangeController {
    @GetMapping("/shop-changes")
    ApiResponse<PageResult<Map<String,Object>>> list(...);

    @GetMapping("/shop-changes/{id}")
    ApiResponse<Map<String,Object>> detail(@PathVariable Long id);

    @PostMapping("/shops/change-drafts")
    ApiResponse<Map<String,Object>> createShopDraft();

    @PostMapping("/shops/{shopId}/change-drafts")
    ApiResponse<Map<String,Object>> createUpdateDraft(@PathVariable Long shopId);

    @PutMapping("/shop-changes/{id}")
    ApiResponse<Map<String,Object>> save(@PathVariable Long id,
            @Valid @RequestBody ShopChangeSaveRequest request);

    @PutMapping("/shop-changes/{id}/photos")
    ApiResponse<Map<String,Object>> savePhotos(@PathVariable Long id,
            @Valid @RequestBody ShopChangePhotosRequest request);

    @PutMapping("/shop-changes/{id}/dishes")
    ApiResponse<Map<String,Object>> saveDishes(@PathVariable Long id,
            @Valid @RequestBody ShopChangeDishesRequest request);

    @PostMapping("/shop-changes/{id}/submit")
    ApiResponse<Map<String,Object>> submit(@PathVariable Long id);
}
```

- [ ] **Step 4: 实现草稿复制、编辑与提交事务**

```java
@Transactional
public Map<String,Object> createUpdateDraft(Long shopId) {
    MerchantSession session = merchant();
    authorizationService.requireShop(session, "shop:edit", shopId);
    ShopChangeRow existing = mapper.selectActiveChange(session.merchantId(), region(), shopId);
    if (existing != null) return changeMap(existing, true);
    ShopChangeRow row = mapper.selectLiveShopSnapshot(shopId, session.merchantId(), region());
    if (row == null) throw new NotFoundException("门店不存在");
    row.setOperatorId(session.operatorId());
    row.setChangeType(2);
    row.setTargetShopId(shopId);
    row.setStatus(0);
    mapper.insertChange(row);
    mapper.copyLivePhotos(row.getId(), shopId);
    mapper.copyLiveDishes(row.getId(), shopId);
    return changeMap(requireChange(row.getId(), session), true);
}

@Transactional
public Map<String,Object> submit(Long changeId) {
    MerchantSession session = merchant();
    ShopChangeRow row = editableChange(changeId, session);
    validateComplete(row, mapper.selectChangePhotos(changeId), mapper.selectChangeDishes(changeId));
    if (mapper.submitChange(changeId, session.merchantId(), region()) != 1) {
        throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
    }
    AuditTaskRow task = pendingTask(5, changeId, region());
    adminAuditMapper.insertAuditTask(task);
    mapper.insertOperationLog(session.merchantId(), session.operatorId(),
            "shop_change_submit", "shop_change", changeId, row.getName());
    return changeMap(requireChange(changeId, session), true);
}
```

保存被驳回申请前执行 `status 3 -> 0` 并清空审核字段；待审、通过和失效状态拒绝编辑。`savePhotos` 和 `saveDishes` 使用先删后批量插入并处于同一事务。

- [ ] **Step 5: 运行商户草稿测试确认 GREEN**

Run: `backend\\mvnw.cmd -Dtest=MerchantShopChangeControllerTest test`

Expected: PASS。

---

### Task 3: 管理审核新建门店 RED/GREEN

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminShopChangeAuditControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/mapper/AdminAuditMapper.java`
- Modify: `backend/src/main/resources/mapper/AdminAuditMapper.xml`

- [ ] **Step 1: 写新门店审核通过失败测试**

测试创建 `change_type=1` 草稿、写基础资料/照片/菜单并提交，断言审核前公开列表不存在候选门店。管理员通过后断言：

```java
mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
        .header("Authorization", bearer(adminToken()))
        .header("X-Region", "EU")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"remark\":\"资料完整\"}"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.bizType").value(5));

assertEquals(1, jdbc.queryForObject(
        "SELECT COUNT(1) FROM shop WHERE merchant_id=2001 AND name='Draft Bistro' AND region='EU'",
        Integer.class
));
assertEquals(2, jdbc.queryForObject(
        "SELECT COUNT(1) FROM shop_photo WHERE shop_id=(SELECT target_shop_id FROM merchant_shop_change WHERE id=?)",
        Integer.class,
        changeId
));
```

- [ ] **Step 2: 运行测试确认 RED**

Run: `backend\\mvnw.cmd -Dtest=AdminShopChangeAuditControllerTest test`

Expected: FAIL，原因是审核服务不支持 `biz_type=5`。

- [ ] **Step 3: 扩展审核任务摘要与分派**

```java
private static final int SHOP_CHANGE_BIZ_TYPE = 5;

if (task.getBizType() == SHOP_CHANGE_BIZ_TYPE) {
    return passShopChangeTask(task, request, requestIp);
}
```

`AdminAuditMapper.xml` 对 `biz_type=5` 关联 `merchant_shop_change` 和 `merchant`，映射：

```sql
CASE WHEN t.biz_type=5 THEN sc.target_shop_id
     WHEN t.biz_type=2 THEN d.shop_id ELSE r.shop_id END AS shop_id,
CASE WHEN t.biz_type=5 THEN sc.name ELSE s.name END AS shop_name,
CASE WHEN t.biz_type=5 THEN sm.company_name
     WHEN t.biz_type=2 THEN m.company_name ELSE r.user_name END AS user_name
```

- [ ] **Step 4: 实现审核通过新建门店事务**

```java
private AdminAuditTaskResponse passShopChangeTask(...) {
    ShopChangeRow change = shopChangeMapper.selectPendingChangeForAudit(task.getBizId(), currentRegion().name());
    if (change == null) throw new NotFoundException("门店变更不存在或已重新提交");
    if (change.getChangeType() == 1) {
        Long shopId = shopChangeService.applyNewShop(change);
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId));
    } else {
        shopChangeService.applyExistingShop(change);
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(change.getTargetShopId()));
    }
    updateTaskAndAuditLog(...);
    return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
}
```

实际状态更新顺序放在同一 `@Transactional` 方法内：先校验申请和线上数据，再更新审核任务/申请并应用快照；任一步失败全部回滚。

- [ ] **Step 5: 运行新建审核测试确认 GREEN**

Run: `backend\\mvnw.cmd -Dtest=AdminShopChangeAuditControllerTest test`

Expected: 新建门店用例 PASS。

---

### Task 4: 修改、驳回与版本冲突 RED/GREEN

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminShopChangeAuditControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/service/MerchantShopChangeService.java`
- Modify: `backend/src/main/resources/mapper/MerchantShopChangeMapper.xml`

- [ ] **Step 1: 写整体替换与聚合字段保留失败测试**

创建 `shopId=20001` 修改草稿并提交。审核前断言旧名称/相册/菜单仍在；通过后断言新快照完整替换，同时：

```java
assertEquals(originalScore, jdbc.queryForObject("SELECT score FROM shop WHERE id=20001", BigDecimal.class));
assertEquals(originalReviewCount, jdbc.queryForObject("SELECT review_count FROM shop WHERE id=20001", Integer.class));
assertEquals(originalHasDeal, jdbc.queryForObject("SELECT has_deal FROM shop WHERE id=20001", Boolean.class));
```

- [ ] **Step 2: 写驳回、重新提交和版本冲突失败测试**

驳回后断言线上三张表不变、草稿 `status=3` 且原因可查；商户修改后再次提交只产生一条新的待审核任务。另一个用例在草稿提交后用管理端更新 `shop.updated_at`，旧任务通过应返回 `400`，线上资料不被覆盖。

- [ ] **Step 3: 实现乐观版本与整体替换**

```sql
SELECT ... FROM shop
WHERE id=#{shopId} AND merchant_id=#{merchantId} AND region=#{region} AND is_deleted=FALSE
FOR UPDATE
```

Java 比较 `current.updatedAt` 与 `change.baseUpdatedAt`；一致后：

```java
requireAffected(mapper.applyShopFields(change));
mapper.deleteLivePhotos(change.getTargetShopId());
mapper.insertLivePhotos(change.getTargetShopId(), mapper.selectChangePhotos(change.getId()));
mapper.deleteLiveDishes(change.getTargetShopId());
mapper.insertLiveDishes(change.getTargetShopId(), mapper.selectChangeDishes(change.getId()));
```

`applyShopFields` 只更新商户可编辑字段，不出现 `score/taste_score/env_score/service_score/review_count/has_deal/merchant_id/region`。

- [ ] **Step 4: 实现审核驳回**

`rejectShopChangeTask` 原子执行审核任务 `0 -> 2`、申请 `1 -> 3`，写 `reject_reason/audit_by/audited_at` 和 `audit_shop_change_reject` 日志；不修改线上表、不发搜索索引事件。

- [ ] **Step 5: 运行管理审核测试确认 GREEN**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=MerchantShopChangeControllerTest,AdminShopChangeAuditControllerTest test
```

Expected: PASS。

---

### Task 5: 权限、校验与回归加固

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantShopChangeControllerTest.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminShopChangeAuditControllerTest.java`

- [ ] **Step 1: 增加校验失败测试**

逐项覆盖：非法分类/城市/商圈、`CN` 非 `CNY`、`EU` 非 `EUR`、经纬度越界、负价格、超过 20 张照片、超过 100 个菜品、无门店图、封面不在相册、重复提交和重复审核。

- [ ] **Step 2: 增加权限与区域失败测试**

覆盖：客服运营无 `shop:edit` 返回 `401`；单店店长访问另一门店返回 `404`；EU 商户用 CN 请求头访问返回 `401/404`；另一个商户访问草稿返回 `404`。

- [ ] **Step 3: 实现最小校验代码并运行定向测试**

校验集中在 `MerchantShopChangeService.validateComplete`，引用检查使用 Mapper 计数，不复制管理端校验逻辑到控制器。

Run: `backend\\mvnw.cmd -Dtest=MerchantShopChangeControllerTest,AdminShopChangeAuditControllerTest test`

Expected: PASS。

- [ ] **Step 4: 运行相关回归**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=AdminManagementControllerTest,PublicBrowseControllerTest,AdminSearchControllerTest,MerchantWorkbenchControllerTest test
```

Expected: PASS，管理端门店 CRUD、公开浏览、搜索索引管理和原商户工作台不回归。

---

### Task 6: 文档、全量验证与阶段收尾

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

Run: `backend\\mvnw.cmd test`

Expected: 全部 PASS，无失败和错误。

- [ ] **Step 2: 同步文档状态**

明确 M5b3 后端已完成，M5b4 点评回复/申诉进入下一阶段；记录门店修改采用完整草稿审核、审核前线上不变、通过后整体替换，以及 `merchant-web` 尚未完成。

- [ ] **Step 3: 检查规格与计划覆盖**

Run:

```powershell
rg -n "M5b3.*未完成|门店/相册/菜单.*未完成|继续完成 M5b3" README.md docs -g '*.md' -g '!docs/superpowers/**'
```

Expected: 无把 M5b3 后端继续列为未完成的旧口径。

- [ ] **Step 4: 执行仓库总门禁**

Run: `./scripts/ci/verify-all.ps1`

Expected: CI 契约、后端测试、Web 单测、Web 构建和管理端构建全部通过，退出码 `0`。

## 计划自审

- 规格中的草稿、照片、菜品、提交、审核、整体应用、驳回、重提、版本冲突、权限、区域、日志和 ES 同步均有对应任务。
- 新建和修改门店分别有 RED/GREEN 验收，不用单一 happy path 冒充全闭环。
- 线上聚合字段明确排除在商户更新 SQL 外。
- H2/MySQL schema 和自增主键同步纳入首个 GREEN 任务。
- 无 `TBD`、`TODO`、“类似上一步”或未定义状态。
