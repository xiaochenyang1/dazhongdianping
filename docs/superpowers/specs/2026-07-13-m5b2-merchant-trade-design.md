# M5b2 商户团购、订单与退款审核设计

## 1. 目标与边界

本阶段补齐商户经营端的团购管理、门店订单查询和退款审核，并把团购审核接入现有运营审核中心。继续复用 M4 已落地的 `deal`、`deal_item`、`order`、`coupon`、`refund`、`payment` 与 `audit_task`，不建立第二套交易状态机。

本阶段包含：

- 商户分页查询、新建、编辑、上下架团购。
- 新建或编辑后自动进入待审核并保持下架。
- 管理端通过统一审核任务审核团购。
- 商户按门店范围查看订单与退款申请。
- 用户退款由“同步完成”改为“提交申请”，商户审核通过后才执行整单退款。
- 团购、退款关键动作写入商户/管理端操作日志。

本阶段不包含部分退款、支付网关真实退款 SDK、自动退款规则、商户端页面和对账中心；这些分别留给 M6、M5c 和后续运营能力。

## 2. 方案选择

### 方案 A：商户直接编辑并即时上架

实现最少，但绕过平台内容与价格审核，和需求中的运营审核中心冲突，不采用。

### 方案 B：建立独立商户团购/订单/退款表

隔离看似清晰，实际会复制 M4 的支付、券和退款状态，产生双写与对账问题，不采用。

### 方案 C：扩展现有交易模型与统一审核中心

商户 API、C 端 API 和管理端审核共享同一组交易表；通过权限、商户归属、区域和门店范围隔离访问。该方案改动集中、状态唯一，采用此方案。

## 3. 接口设计

### 3.1 商户团购

- `GET /api/b/v1/deals`
  - 参数：`shopId`、`auditStatus`、`status`、`page`、`pageSize`。
  - 权限：`deal:edit`。
  - 仅返回当前商户、当前区域且在员工门店范围内的团购。
- `POST /api/b/v1/deals`
  - 权限：`deal:edit`，并校验 `shopId` 门店范围。
  - 创建 `deal` 与 `deal_item`，固定 `audit_status=0`、`status=0`。
  - 创建 `biz_type=2` 的待审核 `audit_task`。
- `PUT /api/b/v1/deals/{id}`
  - 权限：`deal:edit`，并校验团购所属门店范围。
  - 仅允许未产生已支付订单的团购修改价格、类型和套餐内容；已售团购只允许修改展示、库存、有效期与规则，避免历史订单含义漂移。
  - 编辑后固定回到 `audit_status=0`、`status=0`，失效旧待审任务并创建新任务。
- `PUT /api/b/v1/deals/{id}/status`
  - 请求：`status=0|1`。
  - 下架始终允许；上架仅允许 `audit_status=1`、有效期合法且库存不为 0 的团购。

请求校验：标题非空且不超过 128 字，`type` 仅 1 套餐或 2 代金券，金额大于 0、原价不小于售价，币种与门店区域匹配，库存为 `-1` 或非负数，结束日期不早于开始日期，套餐至少一个项目且数量大于 0。

### 3.2 商户订单与退款

- `GET /api/b/v1/orders`
  - 参数：`shopId`、`payStatus`、`refundStatus`、`orderNo`、`dateFrom`、`dateTo`、`page`、`pageSize`。
  - 权限：`order:view`。
  - 仅返回当前商户、区域和员工门店范围内的订单，包含退款摘要。
- `POST /api/b/v1/orders/{id}/refund-audit`
  - 权限：`order:refund`，并校验订单门店范围。
  - 请求：`decision=approve|reject`、`reason`。
  - 只处理该订单最新的 `refund.status=0` 申请。

用户 `POST /api/c/v1/orders/{id}/refund` 调整为提交整单退款申请：校验订单已支付、未存在已核销券、未存在待处理或已成功退款，插入 `refund.status=0`，订单仍保持 `pay_status=1`。响应返回订单和退款摘要。

商户通过退款时，在一个事务内按顺序执行：

1. 原子更新退款 `0 -> 1`。
2. 原子更新订单 `pay_status 1 -> 2`。
3. 将待使用券更新为已退款。
4. 恢复团购库存和销量。
5. 写 `merchant_operation_log`。

任一步失败则整体回滚。商户驳回时仅原子更新退款 `0 -> 2` 并写操作日志，订单和券状态不变。

当前只支持一次整单退款申请。`refund.order_id` 增加唯一约束，直接从数据库层挡住并发重复申请；这比“先查再插”靠谱，后者并发一上来就露馅。

## 4. 团购审核

统一审核接口继续使用：

- `GET /api/admin/v1/audit/tasks?bizType=2`
- `POST /api/admin/v1/audit/tasks/{taskId}/pass`
- `POST /api/admin/v1/audit/tasks/{taskId}/reject`

`AdminAuditService` 按 `biz_type` 分派点评或团购处理：

- 通过团购：审核任务 `0 -> 1`，团购 `audit_status 0 -> 1`，仍保持 `status=0`，由商户主动上架。
- 驳回团购：审核任务 `0 -> 2`，团购 `audit_status 0 -> 2`、`status=0`，保存驳回原因到审核任务。
- 已处理、错区、团购不存在或团购已重新提交时拒绝操作。

审核任务列表对 `biz_type=2` 返回门店、团购标题和商户名称摘要；点评审核响应保持兼容。

## 5. 数据模型与日志

- `deal` 沿用 `audit_status`：`0待审 1通过 2驳回`；`status`：`0下架 1上架`。
- `refund` 沿用 `status`：`0申请中 1退款成功 2驳回`，增加 `audit_by`、`audit_reason`、`audited_at`，并为 `order_id` 增加唯一约束。
- `merchant_operation_log` 记录：`deal_create`、`deal_update`、`deal_on_shelf`、`deal_off_shelf`、`refund_approve`、`refund_reject`。
- `audit_log` 记录：`audit_deal_pass`、`audit_deal_reject`。

H2 `schema.sql` 与 MySQL `sql/mysql/01_schema.sql` 必须同步，种子团购继续保持已审核且已上架，保证现有 C 端用例不受影响。

## 6. 错误与权限

- 缺权限返回 `401`，沿用现有商户授权语义。
- 非当前商户、错区或超出员工门店范围统一返回 `404`，避免泄露资源存在性。
- 状态冲突、非法金额/日期/库存、重复退款申请返回 `400`。
- 所有状态更新使用带旧状态条件的 SQL，受影响行数为 0 时提示刷新重试。

## 7. 测试策略

严格按 RED → GREEN：

- 商户团购：列表隔离、创建待审、编辑重新送审、未审核不可上架、审核通过后上架、跨门店范围拦截。
- 管理审核：团购任务列表摘要、通过、驳回、错区、重复处理。
- 商户订单：分页筛选、区域/商户/门店范围隔离、无 `order:view` 权限拦截。
- 退款：用户提交后订单仍为已支付、重复申请拦截、已核销券拦截、商户通过后的订单/券/库存/退款状态、驳回保持原交易状态、无权限与跨商户拦截、操作日志记录实际员工 ID。
- 回归：现有 C 端下单、支付、券列表和商户核销继续通过。

阶段完成后执行 `backend\\mvnw.cmd test`，再执行仓库根目录 `./scripts/ci/verify-all.ps1`。

## 8. 自审结论

- 无 `TBD`、`TODO` 或未定义状态。
- 团购审核、上下架和公开可见条件一致：审核通过不自动上架。
- 退款只有一套状态源，用户申请与商户审核没有复制交易表。
- 本阶段边界不包含页面、真实支付 SDK、部分退款和自动规则，范围可独立验收。
