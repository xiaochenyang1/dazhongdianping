# Commerce endpoints

## Invoice

- GET /api/c/v1/invoices/orders
- GET /api/c/v1/invoices/titles
- POST /api/c/v1/invoices/titles
- GET /api/c/v1/invoices
- POST /api/c/v1/invoices
- GET /api/admin/v1/invoices
- POST /api/admin/v1/invoices/{id}/issue
- POST /api/admin/v1/invoices/{id}/reject
- POST /api/admin/v1/invoices/{id}/document (multipart: `invoiceNo`, `file`)
- GET /api/admin/v1/invoices/{id}/document
- GET /api/c/v1/invoices/{id}/document
- POST /api/c/v1/invoices/{id}/receipt (JSON: `sha256`)
- GET /api/admin/v1/tax-rates
- PUT /api/admin/v1/tax-rates/{id}

`GET /api/c/v1/invoices/orders` requires a user session. It lists only the current
user's orders in `X-Region` with `pay_status=1` and no invoice request (including
pending, registered or rejected requests). Parameters: `page=1`, `pageSize=12`
(maximum 50), optional positive `orderId` for entry from an order detail page.
Foreign, wrong-region and ineligible IDs return an empty page, without disclosing
whether the order exists. Response data is `{list,total,page,pageSize,hasMore}`;
each item contains `id,orderNo,dealTitle,shopName,amount,currency`. Order selection
is advisory: `POST /invoices` still rechecks ownership, region, payment status,
title ownership and duplicate requests before writing.

Flutter now opens invoicing from a paid order detail or the user centre. Users
select an eligible order and an existing title, or create a personal/company title
with optional email. Company titles require a tax number. Saves select the ID
returned by the server; submissions prevent repeated taps, preserve failed input,
and distinguish a successful request from a subsequent refresh failure. Eligible
orders and request history both paginate. Registered invoice numbers and rejection
reasons are displayed. The existing issue endpoint records a number/status for
compatibility; an actual PDF requires the document endpoint below.

An administrator with `finance:invoice:write` uploads an already issued PDF
(maximum 5 MiB). Pending requests become issued atomically with publication;
registered requests accept a backfill only with their existing invoice number.
PDFBox 3.0.8 parses the bytes in strict mode and rejects malformed, encrypted or
zero-page documents. Same-number, same-SHA-256 retries are idempotent. A different
number or replacement PDF returns 409. This integration does not generate legal
invoices, contact a tax provider, send email, or verify tax signatures/content.

Downloads require the owning user's session and matching `X-Region`, or an admin
with `finance:invoice:read` in that region. They return an attachment named
`invoice-{id}.pdf`, `application/pdf`, `Cache-Control: no-store` and `nosniff`.
No public URL is created. Lists omit binary data and add `documentAvailable`,
`documentFileName`, `documentSha256`, `documentSize`, `documentUploadedAt` and
`receivedAt`. Authorized lists also include order number and invoice title details.
A successful GET never sets receipt: the customer explicitly confirms the expected
SHA-256, returning 409 if it differs. Repeated confirmations preserve the first
receipt timestamp. Admin publication/downloads produce audit records without PDF
bytes or tax details.

Migration `27_invoice_document_delivery_migration.sql` adds a private
`invoice_document` table with bounded MEDIUMBLOB content, SHA-256 and receipt
metadata. Existing migrations and the baseline-14 snapshot are unchanged. Apply
through migration 27 before starting the backend. Include this table in database
backup/restore, use binary-safe dumps (for example `mysqldump --hex-blob`) and a
`max_allowed_packet` comfortably above 5 MiB (16 MiB or higher). Size capacity and
backup time for accumulated PDFs; this implementation does not use public object
storage or deployment-local uploads.

Account export includes document metadata and `invoices/invoice-{id}.pdf` ZIP
entries only when the `invoices` module is selected, across the user's regions.
The account lock serializes publication, export, receipt and deletion; current
locking reads avoid stale snapshots when concurrent MySQL uploads retry. PDFs and
receipt metadata are deleted transactionally during account erasure, while the
existing minimum financial request records remain. Inactive/deleted owners cannot
receive a new PDF. No cleanup version bump is needed because the new table starts
empty and historical deleted owners cannot acquire documents.

## Marketing

- GET /api/b/v1/marketing/coupons
- POST /api/b/v1/marketing/coupons
- GET /api/b/v1/marketing/seckill
- POST /api/b/v1/marketing/seckill
- GET /api/b/v1/marketing/groupbuy
- POST /api/b/v1/marketing/groupbuy
- POST /api/admin/v1/marketing/coupon-templates/{id}/audit
- POST /api/admin/v1/marketing/seckill/{id}/audit
- POST /api/admin/v1/marketing/groupbuy/{id}/audit
- GET /api/admin/v1/groupbuy/operations/summary
- GET /api/admin/v1/groupbuy/operations/teams
- POST /api/admin/v1/groupbuy/operations/teams/{teamId}/reconcile
- GET /api/admin/v1/groupbuy/operations/refunds/failed
- POST /api/admin/v1/groupbuy/operations/refunds/{refundId}/disposition
- GET /api/admin/v1/flags/{id}/scopes
- POST /api/admin/v1/flags/{id}/scopes
- DELETE /api/admin/v1/flags/{id}/scopes/{scopeId}
- GET /api/c/v1/marketing/seckill
- POST /api/c/v1/marketing/seckill/{id}/orders
- POST /api/c/v1/marketing/seckill/{id}/claim（兼容入口，行为与 `/orders` 相同）
- GET /api/c/v1/marketing/groupbuy
- POST /api/c/v1/marketing/groupbuy/{id}/teams
- POST /api/c/v1/marketing/groupbuy/teams/{teamId}/join

### 秒杀订单

秒杀购买已接入普通交易的支付、发券、退款和核销链路。用户需登录并携带当前 `X-Region`，购买请求不接收客户端价格、数量或营销券，每次固定购买一份。成功返回 `{ id, claimId, sold, orderId, order }`；`orderId` 用于打开订单详情和发起支付。兼容的 `/claim` 入口也会创建待支付订单，只有支付成功回调才发券。

- 商户只能选择自己门店已审核、已上架且未过期的套餐；秒杀价格至少 `0.01`、最多两位小数，不能高于套餐价。平台审核通过且在活动时间内才能购买。
- 订单冻结秒杀价、币种、套餐标题、活动标题及券有效期，并返回 `orderSource=seckill`、`campaignId`、`campaignTitle`、`expireAt` 和 `canPay`。后续修改活动或套餐不改变已有订单。
- 同一事务扣减活动名额和套餐库存；普通团购也竞争同一份套餐库存。同一用户并发重试返回同一订单、支付流水及券，不能多占名额。付款期限取下单后 15 分钟、活动结束和套餐有效期结束三者的最早时间。
- 未付款取消或到期会归还两层库存，可重新购买。重试一个刚到期的订单会先返回已关闭的原订单，下一次主动购买才生成新订单。
- 成功付款后每人每场限购一次，退款后仍保留限购记录。退款成功只归还一次库存；退款待审核或处理中不允许核销，已核销订单不允许整单退款。
- 已关闭订单收到迟到支付时不发券，创建 `refundType=late_payment` 的自动退款记录；渠道暂时不可用时由补偿任务用同一渠道幂等键继续提交，异步退款通过既有回调或对账完成。
- 列表返回 `availableStock`（活动和套餐的可售库存较小值）、`perUserLimit=1`、`participationStatus`、`orderId`。参与状态为 `0` 历史记录、`1` 待支付、`2` 已支付、`3` 已释放、`4` 已退款；历史记录不补订单、不补发券。注销清理参与记录时保留真实订单占用及历史已售名额。

部署前按顺序应用 [`29_seckill_order_migration.sql`](../../sql/mysql/29_seckill_order_migration.sql)。全新库导入基础快照后使用基线 14，增量升级到 29。默认 `APP_LAUNCH_DEFERRED_FEATURES_ENABLED=false`，EU 秒杀还受 `APP_LAUNCH_EU_SECKILL_ENABLED=false` 限制；仅在独立开发环境显式开启，现有巴黎首发开关不变。

本地复现：`python3 scripts/ci/seckill-order-integration.py --server local`。脚本会创建私有 MySQL 数据目录和临时账号，运行真实事务并发用例及 CN/EU 三端浏览器购买、退款、核销流程，结束后清理服务；不会连接现有业务库。CI/nightly 使用 `--server docker` 和 MySQL 8.4。验证范围与证据见[交付记录](../秒杀订单交易闭环-2026-11-06.md)。

### 拼团交易与运营

每位成员开团或参团时创建一笔独立待支付订单，并在同一事务中占用拼团名额和套餐库存。成员付款只更新本人成员状态；达到活动人数后只允许一次状态跃迁为已成团，再为全部已付款订单逐单发券。并发付款和重复渠道回调均保持幂等。

- 进行中的团到期后，未付款订单关闭并释放库存，已付款订单创建 `refundType=groupbuy_expired` 的自动退款；提交超时或响应丢失等不确定结果由补偿任务使用稳定幂等键重试，渠道明确返回失败则保留原订单、券和库存并进入运营告警，不自动重提资金。此前被驳回但尚未出账的用户退款会转为到期自动退款。已成团订单继续复用普通券核销和退款约束。
- 订单详情返回 `groupBuyTeamId/groupBuyStatus/groupBuyMemberCount/groupBuyPaidCount/groupBuySize`。Web 与 Flutter 在进行中展示实时倒计时和邀请链接 `/marketing/groupbuy?teamId={teamId}`；Web 直达页面会预填团号。
- 截止前 60 分钟内向仍有效成员发送一次 `groupbuy.deadline` 站内通知，`groupbuy_member.remind_status` 保证持久去重；成团发券发送 `groupbuy.formed`。
- 管理端 `/data/groupbuy-operations` 使用 `data:order:read|write` 权限，并遵守管理员区域、城市和门店范围。摘要会提示过期未处理、退款等待/失败、已成团缺券和库存未释放；单团修复可重跑未提交的到期处理和缺券发放，并记录实际处理数、失败数与审计日志。渠道明确失败的退款不会由单团修复或定时任务重提资金，而是进入人工核验队列。
- `GET /api/admin/v1/groupbuy/operations/refunds/failed` 分页返回当前范围内 `refund.status=4`、`refundType=groupbuy_expired` 的终态失败记录。`POST /refunds/{refundId}/disposition` 接收 `outcome`、`providerReference`、`note`：`provider_not_refunded` 只保存渠道核验编号、备注和管理员审计，退款保持失败且告警继续开放；`provider_refunded` 要求操作员已在渠道后台确认实际到账，将退款 `4 -> 1` 并幂等补齐订单已退款、券退款、库存释放和用户通知。两种结论都不会调用退款 API；成功结论的重复提交不会重复释放库存或通知。原 `channelRefundTxn` 始终保留，人工核验编号写入审核记录，避免覆盖原渠道失败证据。
- Micrometer 指标为 `dianping.groupbuy.lifecycle` 和 `dianping.groupbuy.failure`。成功生命周期事件在事务提交后记录，避免回滚事务产生虚假成功数。
- 部署总开关 `APP_LAUNCH_DEFERRED_FEATURES_ENABLED` 必须先开启；随后由区域 `group_buy` 总开关与活动 > 门店 > 城市规则决定用户是否可用，同级按稳定用户哈希执行 `rolloutPercent`。CN/EU 的总开关种子均为关闭；`APP_LAUNCH_GROUP_BUY_FEATURE_FLAG_ENFORCED` 默认 `true`。

部署前按顺序应用 [`30_groupbuy_order_migration.sql`](../../sql/mysql/30_groupbuy_order_migration.sql) 和 [`31_groupbuy_rollout_migration.sql`](../../sql/mysql/31_groupbuy_rollout_migration.sql)。迁移契约和本地真实 MySQL 8 的旧库、全新库、重复执行、锁与 checksum 漂移验证均覆盖到版本 31。

## Ads

- GET /api/b/v1/ads/report

## Analytics

- GET /api/b/v1/analytics/trend
- GET /api/b/v1/analytics/export
