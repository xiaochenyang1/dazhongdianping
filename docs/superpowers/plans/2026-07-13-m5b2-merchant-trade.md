# M5b2 Merchant Trade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成商户团购管理、门店订单查询、退款审核和运营团购审核，并复用现有 M4 交易状态机。

**Architecture:** 新增独立的 `merchant/trade` 控制器、服务与 Mapper，避免继续膨胀已有 `MerchantWorkbenchController`；C 端退款申请仍由 `TradeService` 负责，商户审核在同一组 `order/coupon/refund/deal` 表内事务执行；运营审核扩展现有 `AdminAuditService` 的 `biz_type` 分派。

**Tech Stack:** Java 17、Spring Boot、MyBatis、H2/MySQL、JUnit 5、MockMvc。

---

### Task 1: 商户团购控制器契约 RED

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantDealControllerTest.java`

- [ ] **Step 1: 写创建待审、未审核不可上架、审核后上架的失败测试**

测试通过 owner 登录后调用：

```java
mockMvc.perform(post("/api/b/v1/deals")
        .header("Authorization", bearer(ownerToken))
        .header("X-Region", "EU")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {"shopId":20001,"type":1,"title":"双人套餐","coverImage":"/deal.jpg",
             "price":49.90,"originalPrice":68.00,"currency":"EUR","stock":20,
             "validStart":"2026-07-13","validEnd":"2026-12-31","rules":"预约使用",
             "items":[{"name":"主菜","quantity":2,"price":0,"sort":1}]}
            """))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.auditStatus").value(0))
    .andExpect(jsonPath("$.data.status").value(0));
```

随后断言数据库存在 `biz_type=2,status=0` 审核任务；调用 `PUT /deals/{id}/status` 上架应为 `400`；管理员审核通过后再次上架应成功。

- [ ] **Step 2: 写编辑重新送审与门店范围隔离失败测试**

创建只授权 `shopId=20001` 的店长，验证其不能创建/编辑 `shopId=20002` 团购；编辑已审核团购后断言 `audit_status=0,status=0` 且仅有一条有效待审任务。

- [ ] **Step 3: 运行测试确认 RED**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=MerchantDealControllerTest test
```

Expected: FAIL，原因是 `/api/b/v1/deals` 尚不存在。

---

### Task 2: 商户团购最小实现 GREEN

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/controller/MerchantTradeController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/service/MerchantTradeService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/mapper/MerchantTradeMapper.java`
- Create: `backend/src/main/resources/mapper/MerchantTradeMapper.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/MerchantDealRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/MerchantOrderRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/RefundRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/request/MerchantDealSaveRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/request/MerchantDealItemRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/request/MerchantDealStatusRequest.java`

- [ ] **Step 1: 定义请求与控制器接口**

```java
public record MerchantDealStatusRequest(@NotNull @Min(0) @Max(1) Integer status) {}

@GetMapping("/deals")
ApiResponse<PageResult<Map<String,Object>>> deals(Long shopId, Integer auditStatus,
        Integer status, Integer page, Integer pageSize);

@PostMapping("/deals")
ApiResponse<Map<String,Object>> createDeal(@Valid @RequestBody MerchantDealSaveRequest request);

@PutMapping("/deals/{id}")
ApiResponse<Map<String,Object>> updateDeal(@PathVariable Long id,
        @Valid @RequestBody MerchantDealSaveRequest request);

@PutMapping("/deals/{id}/status")
ApiResponse<Map<String,Object>> changeDealStatus(@PathVariable Long id,
        @Valid @RequestBody MerchantDealStatusRequest request);
```

- [ ] **Step 2: 实现 Mapper SQL**

关键 SQL 必须包含：

```sql
INSERT INTO deal(..., audit_status, status, ...)
VALUES(..., 0, 0, ...)

UPDATE deal
SET ..., audit_status=0, status=0, updated_at=CURRENT_TIMESTAMP
WHERE id=#{dealId} AND merchant_id=#{merchantId} AND region=#{region} AND is_deleted=FALSE

UPDATE deal
SET status=#{status}, updated_at=CURRENT_TIMESTAMP
WHERE id=#{dealId} AND merchant_id=#{merchantId} AND region=#{region}
  AND (#{status}=0 OR (audit_status=1 AND stock&lt;&gt;0
       AND (valid_end IS NULL OR valid_end&gt;=CURRENT_DATE)))
```

列表与详情 SQL 同时限定 `merchant_id`、`region`、`is_deleted=FALSE` 和授权门店集合；保存套餐项时先删后插；编辑前用已支付订单计数限制历史语义字段。

- [ ] **Step 3: 实现服务事务与审核任务**

`createDeal`/`updateDeal`：

```java
authorizationService.requireShop(session, "deal:edit", request.shopId());
validateDeal(request);
mapper.insertDeal(row); // 或 updateDeal
mapper.replaceDealItems(row.getId(), request.items());
adminAuditMapper.invalidatePendingAuditTasksByBiz(2, row.getId(), "团购已重新提交");
adminAuditMapper.insertAuditTask(pendingDealTask(row));
mapper.insertMerchantOperationLog(session.merchantId(), session.operatorId(),
        action, "deal", row.getId(), request.title());
```

编辑现有团购时先按商户/区域取详情，再校验实际门店范围；不能直接相信请求里的 `shopId`。

- [ ] **Step 4: 运行测试确认 GREEN**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=MerchantDealControllerTest test
```

Expected: PASS。

---

### Task 3: 运营团购审核 RED/GREEN

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminDealAuditControllerTest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/model/AuditTaskRow.java`
- Modify: `backend/src/main/resources/mapper/AdminAuditMapper.xml`

- [ ] **Step 1: 写团购审核列表、通过、驳回失败测试**

验证 `GET /audit/tasks?bizType=2` 返回 `shopName/submittedBy/summary`；通过后 `deal.audit_status=1,status=0`；驳回后 `audit_status=2,status=0`；错区和重复审核被拒绝。

- [ ] **Step 2: 运行测试确认 RED**

Run: `backend\\mvnw.cmd -Dtest=AdminDealAuditControllerTest test`

Expected: FAIL，原因是现有服务只接受点评任务。

- [ ] **Step 3: 按 biz_type 分派审核**

```java
return switch (task.getBizType()) {
    case 2 -> passDealTask(task, request, requestIp);
    case 3 -> passReviewTask(task, request, requestIp);
    default -> throw new IllegalArgumentException("当前不支持此审核任务");
};
```

团购审核 SQL：

```sql
UPDATE deal SET audit_status=#{auditStatus}, status=0, updated_at=CURRENT_TIMESTAMP
WHERE id=#{dealId} AND region=#{region} AND audit_status=0 AND is_deleted=FALSE
```

审核列表 Mapper 对 `biz_type=2` 关联 `deal/shop/merchant`，用 `CASE` 统一映射摘要字段，保持点评返回结构不变。

- [ ] **Step 4: 运行测试确认 GREEN**

Run: `backend\\mvnw.cmd -Dtest=AdminDealAuditControllerTest,AdminAuditControllerTest test`

Expected: PASS。

---

### Task 4: 用户退款申请状态机 RED

**Files:**
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/trade/controller/TradeControllerTest.java`

- [ ] **Step 1: 把同步退款断言改为待审核申请**

```java
mockMvc.perform(post("/api/c/v1/orders/{id}/refund", orderId)
        .header("Authorization", bearer(token))
        .header("X-Region", "CN")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"reason\":\"行程有变\"}"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.payStatus").value(1))
    .andExpect(jsonPath("$.data.refund.status").value(0));
```

增加重复申请、已核销券申请失败用例。

- [ ] **Step 2: 运行测试确认 RED**

Run: `backend\\mvnw.cmd -Dtest=TradeControllerTest test`

Expected: FAIL，现有实现会立即把订单标成已退款。

---

### Task 5: 用户退款申请 GREEN 与数据库约束

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/service/TradeService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/trade/mapper/TradeMapper.java`
- Modify: `backend/src/main/resources/mapper/TradeMapper.xml`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`

- [ ] **Step 1: 同步 H2/MySQL refund 字段与唯一约束**

```sql
audit_by BIGINT NOT NULL DEFAULT 0,
audit_reason VARCHAR(255) NOT NULL DEFAULT '',
audited_at DATETIME NULL,
UNIQUE KEY uk_refund_order(order_id)
```

H2 使用等价类型和 `CREATE UNIQUE INDEX IF NOT EXISTS`。

- [ ] **Step 2: 改造 TradeService.refund 为提交申请**

```java
if (o.getPayStatus() != 1 || o.getStatus() != 1) throw ...;
if (mapper.countUsedCoupons(id) > 0) throw ...;
if (mapper.selectRefundByOrder(id) != null) throw new IllegalArgumentException("订单已有退款申请");
mapper.insertRefund(id, o.getAmount(), req.reason().trim()); // status 固定 0
return orderMap(requireOrder(id), true);
```

`orderMap` 增加 `refund` 摘要；删除这里对订单、券和库存的直接更新。

- [ ] **Step 3: 运行测试确认 GREEN**

Run: `backend\\mvnw.cmd -Dtest=TradeControllerTest test`

Expected: PASS。

---

### Task 6: 商户订单与退款审核 RED

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantOrderControllerTest.java`

- [ ] **Step 1: 写订单分页与范围隔离失败测试**

验证 owner 可按 `shopId/payStatus/refundStatus/orderNo/dateFrom/dateTo` 查询；只授权单店员工看不到另一门店；无 `order:view` 权限返回 `401`。

- [ ] **Step 2: 写退款通过与驳回失败测试**

退款通过后断言：

```java
assertEquals(1, refundStatus);
assertEquals(2, orderPayStatus);
assertEquals(4, couponStatus);
assertEquals(originalStock, restoredStock);
assertEquals(staffId, operationLogOperatorId);
```

驳回后断言 `refund.status=2`，订单仍 `pay_status=1`，券仍待使用，库存不变。再覆盖跨商户、无 `order:refund` 权限和重复审核。

- [ ] **Step 3: 运行测试确认 RED**

Run: `backend\\mvnw.cmd -Dtest=MerchantOrderControllerTest test`

Expected: FAIL，原因是商户订单与退款审核接口尚不存在。

---

### Task 7: 商户订单与退款审核 GREEN

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/controller/MerchantTradeController.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/service/MerchantTradeService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/mapper/MerchantTradeMapper.java`
- Modify: `backend/src/main/resources/mapper/MerchantTradeMapper.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/trade/model/request/MerchantRefundAuditRequest.java`

- [ ] **Step 1: 实现订单列表接口**

```java
@GetMapping("/orders")
ApiResponse<PageResult<Map<String,Object>>> orders(Long shopId, Integer payStatus,
        Integer refundStatus, String orderNo, LocalDate dateFrom, LocalDate dateTo,
        Integer page, Integer pageSize);
```

无 `shopId` 时 Mapper 使用授权门店集合；全门店 owner 传 `null` 表示不额外限制。日期最大跨度 90 天。

- [ ] **Step 2: 实现退款审核原子状态迁移**

```java
authorizationService.requireShop(session, "order:refund", order.getShopId());
RefundRow refund = requirePendingRefund(orderId);
if (approve) {
    requireAffected(mapper.approveRefund(refund.getId(), session.operatorId(), reason));
    requireAffected(mapper.markMerchantOrderRefunded(orderId));
    mapper.markMerchantCouponsRefunded(orderId);
    mapper.restoreMerchantDealStock(order.getDealId(), order.getQuantity());
} else {
    requireAffected(mapper.rejectRefund(refund.getId(), session.operatorId(), reason));
}
mapper.insertMerchantOperationLog(...);
```

所有更新置于同一 `@Transactional` 方法中，且 SQL 都带旧状态条件。

- [ ] **Step 3: 运行测试确认 GREEN**

Run:

```powershell
cd backend
./mvnw.cmd -Dtest=MerchantOrderControllerTest,TradeControllerTest test
```

Expected: PASS。

---

### Task 8: 回归、重构与文档

**Files:**
- Modify: `README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/业务流程与状态机.md`
- Modify: `docs/测试清单与验收用例.md`

- [ ] **Step 1: 运行后端全量测试**

Run:

```powershell
cd backend
./mvnw.cmd test
```

Expected: 全部 PASS，无失败和错误。

- [ ] **Step 2: GREEN 后格式化本阶段触及的压缩 Java/XML**

至少整理 `TradeService.java`、`TradeMapper.xml` 和新增文件，保持方法职责清晰；格式化后重新运行后端全量测试。

- [ ] **Step 3: 同步文档状态与测试数量**

明确 M5b2 已完成、M5b3 进入下一阶段；记录用户退款从同步完成改为待商户审核，真实支付网关退款仍未接。

- [ ] **Step 4: 执行仓库全量门禁**

Run:

```powershell
./scripts/ci/verify-all.ps1
```

Expected: CI 契约、后端、Web 测试和 Web/admin-web 构建全部通过，命令退出码 0。

## 计划自审

- 设计中的每个接口、权限、状态与日志均有对应任务。
- 无 `TBD`、`TODO`、“后续补”等占位步骤。
- `refund.status`、`deal.audit_status`、请求字段和 Mapper 方法名在各任务中一致。
- 计划不包含 M5b3/M5b4 页面或真实支付 SDK，范围保持可独立验收。
