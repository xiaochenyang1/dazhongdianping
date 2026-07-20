# M5b4 商户点评经营设计

## 1. 目标

完成商户点评经营后端闭环：商户员工只能查看其授权门店的公开点评，可以直接发布或编辑商家回复，也可以针对涉嫌恶意的点评提交申诉。申诉复用管理端统一审核中心，审核通过后隐藏点评并重算门店评分，审核驳回后点评保持公开且商户可修改申诉后重提。

本阶段只实现后端 API、H2/MySQL 数据结构、审核流程、公开端回复展示、自动化测试和文档回填。独立 `merchant-web` 页面、管理端门店申诉页面和 WebSocket 通知仍属于 M5c/M5d。

## 2. 已确认业务规则

- 商户点评列表只展示 `audit_status=1`、`status=1`、未删除的公开点评。
- 商家回复发布后直接公开，不再经过管理员审核。
- 每条点评最多一条当前商家回复；再次提交执行覆盖更新。
- 回复允许编辑，每次创建或编辑都记录实际商户员工与操作日志。
- 申诉待审核期间点评继续公开。
- 同一商户对同一点评复用一条申诉记录，同一时间不能重复提交待审申诉。
- 申诉驳回后允许修改理由和证据并重新提交，新一轮提交生成新的审核任务。
- 申诉通过后点评从公开端隐藏，门店评分和点评数立即重算。
- 商户只能操作其所属商户、当前区域和员工门店范围内的点评。

## 3. 领域边界

新增独立 `module/merchant/review` 领域模块，负责商户点评查询、回复和申诉。现有 `module/review` 继续负责 C 端点评创建、编辑、互动、用户举报与公开详情；管理端 `AdminAuditService` 负责申诉审核分派。

边界约束：

- 商户模块通过独立 Mapper 查询点评，不把商户会话、门店范围和权限判断塞进 C 端 `ReviewService`。
- C 端公开响应只读取已经公开的商家回复，不返回申诉理由、证据、状态或审核备注。
- 管理端通过 `biz_type=6` 识别商户点评申诉，不复用 `review_report`。用户举报和商户申诉语义不同，硬塞一张表只会把权限和状态机搅成浆糊。
- 评分聚合继续复用 `ReviewService.recalculateShopAggregate`，不复制第二套聚合算法。

## 4. 数据模型

### 4.1 `review_merchant_reply`

保存每条点评当前有效的商家回复。

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | BIGINT | 自增主键 |
| `review_id` | BIGINT | 点评 ID，唯一 |
| `shop_id` | BIGINT | 冗余门店 ID，便于范围查询 |
| `merchant_id` | BIGINT | 商户主体 ID |
| `operator_id` | BIGINT | 最后回复或编辑员工 |
| `content` | VARCHAR(500) | 回复正文 |
| `created_at` | TIMESTAMP | 首次回复时间 |
| `updated_at` | TIMESTAMP | 最后编辑时间 |

约束与索引：

- 唯一键 `uk_review_merchant_reply_review(review_id)`。
- 索引 `idx_review_merchant_reply_shop(shop_id,updated_at)`。
- 回复内容去除首尾空白后长度必须为 `1-500`。

### 4.2 `merchant_review_appeal`

保存商户针对点评的当前申诉记录。每个 `merchant_id + review_id` 只保留一条当前记录，历次审核结论通过 `audit_task`、`audit_log` 和 `merchant_operation_log` 留痕。

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | BIGINT | 自增主键 |
| `merchant_id` | BIGINT | 商户主体 ID |
| `operator_id` | BIGINT | 最后编辑或提交员工 |
| `review_id` | BIGINT | 被申诉点评 |
| `shop_id` | BIGINT | 点评所属门店 |
| `region` | VARCHAR(8) | 数据区域 |
| `base_review_updated_at` | TIMESTAMP | 提交时点评版本 |
| `reason` | VARCHAR(500) | 申诉理由 |
| `evidence_urls` | VARCHAR(2000) | 最多 6 个证据 URL 的 JSON 数组 |
| `status` | TINYINT | `0草稿 1待审核 2通过 3驳回 4失效` |
| `reject_reason` | VARCHAR(255) | 管理员驳回原因 |
| `audit_by` | BIGINT | 审核管理员 |
| `submitted_at` | TIMESTAMP | 最近提交时间 |
| `audited_at` | TIMESTAMP | 最近审核时间 |
| `created_at` | TIMESTAMP | 创建时间 |
| `updated_at` | TIMESTAMP | 更新时间 |

约束与索引：

- 唯一键 `uk_merchant_review_appeal(merchant_id,review_id)`。
- 索引 `idx_merchant_review_appeal_status(merchant_id,region,status,id)`。
- 索引 `idx_merchant_review_appeal_shop(shop_id,status,id)`。
- 理由去除首尾空白后长度必须为 `10-500`。
- 证据 URL 可为空，最多 6 个，每个 URL 最长 255 字符。

### 4.3 审核类型

`audit_task.biz_type` 增加：

- `6`：商户点评申诉。

管理端任务摘要对 `biz_type=6` 映射申诉门店、点评用户、点评正文和商户名称。

## 5. 商户端 API

所有接口位于 `/api/b/v1`，要求商户资质已通过且请求 `X-Region` 与商户经营区域一致。

### 5.1 点评分页

`GET /reviews`

查询参数：

- `shopId`：可选；指定时校验员工门店范围。
- `replyStatus`：可选，`0未回复 1已回复`。
- `appealStatus`：可选，`0草稿 1待审核 2通过 3驳回 4失效`。
- `score`：可选，按综合评分精确筛选。
- `keyword`：可选，匹配点评正文或用户昵称。
- `dateFrom/dateTo`：可选，最大跨度 90 天。
- `page/pageSize`：默认 `1/20`，最大 `100`。

未指定 `shopId` 时：

- 主账号和全部门店范围员工查询当前商户全部门店。
- 指定门店范围员工只查询授权门店。
- 结果只包含公开点评，不暴露用户待审、驳回、隐藏或删除内容。

响应项包括点评 ID、门店、用户、正文、四项评分、消费金额、图片、标签、点赞数、评论数、当前商家回复、最新申诉状态和创建时间。

### 5.2 商家回复

`PUT /reviews/{reviewId}/reply`

请求：

```json
{
  "content": "感谢您的反馈，我们已经调整了出餐流程。"
}
```

行为：

- 需要 `review:reply` 权限。
- 校验点评属于当前商户、当前区域、员工授权门店，并且仍是公开点评。
- 不存在回复时插入，存在时覆盖内容和 `operator_id`。
- 写入 `merchant_operation_log`，动作分别为 `review_reply_create` 或 `review_reply_update`。
- 返回当前回复内容、商户名称、实际员工、首次回复时间和最后编辑时间。

### 5.3 创建申诉草稿

`POST /reviews/{reviewId}/appeal-drafts`

行为：

- 需要 `review:appeal` 权限。
- 校验点评属于当前商户、当前区域、员工授权门店，并且仍是公开点评。
- 记录不存在时创建空草稿。
- 状态为 `0草稿` 或 `1待审核` 时返回现有记录，避免重复创建。
- 状态为 `3驳回` 时仍返回原记录，等待商户编辑。
- 状态为 `2通过` 或 `4失效`，但点评后来经过用户编辑和平台审核重新公开时，重置为新草稿并记录新的点评版本。

### 5.4 保存申诉

`PUT /review-appeals/{appealId}`

请求：

```json
{
  "reason": "点评内容包含与实际消费无关的人身攻击，请平台复核。",
  "evidenceUrls": [
    "https://files.example/order-proof.jpg"
  ]
}
```

行为：

- 需要 `review:appeal` 权限和门店范围。
- `0草稿` 可直接编辑。
- `3驳回` 首次编辑时重置为 `0草稿`，清空旧审核字段。
- `1待审核` 不允许编辑。
- `2通过`、`4失效` 只有在点评新版本重新公开后才能由创建草稿接口重置。

### 5.5 提交申诉

`POST /review-appeals/{appealId}/submit`

行为：

- 校验理由、证据数量、点评仍公开、点评版本未变化。
- 申诉状态原子执行 `0 -> 1`。
- 保存当前 `review.updated_at` 到 `base_review_updated_at`。
- 新增 `audit_task(biz_type=6,biz_id=appealId,status=0)`。
- 写入 `merchant_operation_log(action=review_appeal_submit)`。
- 重复提交返回 `400`，不生成重复待审任务。

## 6. 公开端调整

门店点评列表和点评详情增加可空字段 `merchantReply`：

```json
{
  "merchantName": "Maison Sichuan SARL",
  "content": "感谢反馈，我们已经联系门店改进。",
  "repliedAt": "2026-07-14 16:00:00",
  "updatedAt": "2026-07-14 16:10:00"
}
```

公开查询必须同时满足点评公开条件。点评隐藏后，回复记录仍保留，但因为点评本身不可见，回复也不会单独暴露。

申诉 ID、理由、证据、状态、审核人和审核备注全部不进入 C 端响应。

## 7. 管理端审核

继续复用：

- `GET /api/admin/v1/audit/tasks`
- `POST /api/admin/v1/audit/tasks/{taskId}/pass`
- `POST /api/admin/v1/audit/tasks/{taskId}/reject`

### 7.1 通过申诉

在单个事务内执行：

1. 校验任务属于当前区域、`biz_type=6` 且状态为待审。
2. 锁定申诉和点评。
3. 校验申诉 `status=1`、点评仍公开、点评 `updated_at` 等于 `base_review_updated_at`。
4. 原子抢占审核任务 `0 -> 1`。
5. 将点评 `audit_status` 更新为 `2驳回`，`audit_remark` 写入“商户申诉通过”及管理员备注。
6. 将申诉更新为 `2通过`，记录审核人和审核时间。
7. 处理该点评待处理的 `review_report`，并使其他点评审核待办失效。
8. 重算门店评分和点评数。
9. 写入 `audit_log(action=audit_review_appeal_pass)` 和商户操作日志。
10. 事务提交后发布 `ShopSearchIndexChangedEvent`。

任何一步失败，任务、申诉、点评和评分聚合全部回滚。

### 7.2 驳回申诉

在单个事务内执行：

1. 原子抢占审核任务 `0 -> 2`。
2. 申诉 `1 -> 3`，写入驳回原因、审核人和审核时间。
3. 写入 `audit_log(action=audit_review_appeal_reject)` 和商户操作日志。
4. 点评继续公开，不更新点评、不重算评分、不发布搜索事件。

## 8. 点评版本与其他审核流程协作

- 商户提交申诉时保存点评版本。
- 用户编辑或删除点评时，使该点评活动申诉和 `biz_type=6` 待审任务失效，原因分别记录“点评已编辑”或“点评已删除”。
- 管理员通过其他点评审核使点评继续公开时，待审商户申诉可继续处理，但仍必须通过版本校验。
- 管理员通过用户举报而驳回点评时，使商户申诉失效，因为点评已经被平台隐藏。
- 商户申诉通过时，使该点评其他 `biz_type=3` 待审任务失效，并处理待处理用户举报，避免两个审核员继续对同一旧内容作相反决策。
- 点评被用户编辑并重新审核公开后，商户可以基于新版本重新创建申诉草稿。

## 9. 权限与隔离

- 点评列表需要 `shop:view`。
- 回复需要 `review:reply`。
- 申诉创建、编辑和提交需要 `review:appeal`。
- 主账号、店长和客服运营按数据库权限执行。
- 核销员没有回复和申诉权限。
- 指定门店范围员工访问其他门店点评返回 `404`。
- 跨商户、跨区域、已删除或非公开点评统一按资源不存在处理，不暴露数据存在性。

## 10. 校验与错误处理

- 非法分页、评分、日期跨度、回复内容、申诉理由和证据数量返回 `400`。
- 权限点缺失返回 `401`。
- 资源不属于当前商户、区域或门店范围返回 `404`。
- 待审申诉重复提交、待审状态编辑、重复审核和版本冲突返回 `400`。
- MyBatis 更新受影响行数必须为 `1`，否则按状态竞争处理，事务回滚。
- 回复和申诉所有写操作必须落实际 `merchant_operator.id`，不能用 `merchant_id` 冒充操作人。

## 11. 测试设计

### 11.1 商户点评列表与回复

- 主账号查询全部门店公开点评。
- 指定门店员工只能查询授权门店。
- 待审、驳回、隐藏和已删除点评不进入列表。
- 评分、关键词、回复状态、申诉状态和日期筛选正确。
- 回复创建后 C 端列表和详情立即可见。
- 回复编辑覆盖原记录，保留首次时间并更新员工与编辑时间。
- 核销员无权限，跨商户、跨区域和跨门店访问被拦截。

### 11.2 申诉与审核

- 创建草稿、保存理由/证据、提交生成 `biz_type=6` 待审任务。
- 待审期间点评保持公开。
- 重复创建返回现有活动申诉，重复提交不产生第二条待审任务。
- 驳回不改变点评和门店评分，商户修改后可重提。
- 通过后点评不可公开访问，门店评分和点评数重新计算。
- 通过后保留商家回复记录，但不再公开暴露。
- 点评编辑、删除、其他审核隐藏和版本冲突使申诉失效或阻止审核。
- 重复审核、错区域审核和并发抢占只允许一个决策成功。

### 11.3 回归

- 原 C 端点评创建、编辑、删除、举报、点赞、评论与用户点评列表不回归。
- 原管理端点评审核、门店评分聚合和用户举报处理不回归。
- 公开门店详情、点评详情和搜索索引同步不回归。
- H2 与 MySQL Schema 同步。
- 后端全量测试、Web 单测/构建、Admin Web 构建和仓库总门禁全部通过。

## 12. 文档与阶段边界

完成后更新 `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/测试清单与验收用例.md` 和 `docs/当前已完成功能与SQL导入说明.md`。

M5b4 完成只代表商户点评经营后端闭环完成。以下内容仍不应标记完成：

- M5c 独立 `merchant-web`。
- M5d WebSocket 通知和管理端商户申诉页面。
- 真实外部环境凭证联调与发布回滚演练。
