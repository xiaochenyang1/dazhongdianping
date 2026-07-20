# M5b1 商户预订工作台与经营看板设计

## 1. 范围

本批完成 B 端预订列表、详情、商户改期和经营看板，并把已有确认、拒绝、到店、爽约、券核销动作接入 M5a 的员工权限和门店范围。门店编辑、团购管理、订单退款和点评回复继续由后续 M5b 子批完成。

## 2. 预订查询

- `GET /api/b/v1/reservations` 支持 `shopId、status、dateFrom、dateTo、page、pageSize`。
- `GET /api/b/v1/reservations/{id}` 返回联系人、门店、时段、状态、可执行动作和完整时间线。
- 主账号可查看全部门店；指定门店员工只能查看 `merchant_operator_shop` 内的门店。
- 列表和详情同时校验 `merchant_id、region、shop scope`，越权统一返回不存在或无权限，不泄露其他商户数据。

## 3. 商户改期

- `POST /api/b/v1/reservations/{id}/reschedule` 仅允许状态 `0待确认` 或 `1已确认`。
- 新时段必须属于原门店与当前区域；先原子占用新时段，更新成功后再释放旧时段，失败回滚。
- 新时段自动确认则状态为 `1`，人工确认则状态为 `0`。
- 变更日志动作码使用 `6商户改期`，`operator_type=2`，`operator_id` 写实际 `merchant_operator.id`，不再写商户主体 ID。

## 4. 权限

- 列表/详情/看板：`reservation:view` 或 `dashboard:view`。
- 确认、拒绝、改期：`reservation:confirm`。
- 到店、爽约：`reservation:arrive`；`owner/store_manager` 的种子权限补齐该权限。
- 券核销：`coupon:verify`。
- 所有动作调用 `MerchantAuthorizationService.requireShop`，SQL 继续保留商户归属条件。

## 5. 经营看板

`GET /api/b/v1/dashboard?shopId=&dateFrom=&dateTo=` 返回：

- `views`：公开门店详情按 `shop_view_daily` 真实日聚合。
- `paidOrders/paidAmount`：已支付订单数量和金额。
- `verifiedCoupons`：已核销券数量。
- `reservations`：总数、待确认、已确认、已到店、拒绝、爽约。
- `rating`：门店当前平均分和点评数。
- `trend`：按日期返回浏览、下单、核销、预订四条序列，缺失日期补零。

默认最近 7 天，最长查询 90 天；指定 `shopId` 时必须在操作者门店范围内。

## 6. 测试

- 集成测试覆盖过滤列表、详情时间线、商户改期容量交换和重新确认规则。
- 权限测试覆盖核销员不能确认、指定门店员工不能查看另一门店、操作日志写实际员工 ID。
- 看板测试通过真实访问门店详情、支付、核销和预订数据验证聚合，不使用 mock 数字。
- 最后运行后端全量测试和 `scripts/ci/verify-all.ps1`。

## 7. 自审

设计无占位项；浏览量来源、权限码、动作码、改期事务顺序和最大日期范围均已明确。
