-- Stripe 退款异步状态与失败原因。可重复执行前请先确认字段尚不存在。
ALTER TABLE `refund`
  ADD COLUMN `channel_status` VARCHAR(32) NOT NULL DEFAULT '' AFTER `channel_refund_txn`,
  ADD COLUMN `channel_failure_reason` VARCHAR(255) NOT NULL DEFAULT '' AFTER `channel_status`,
  ADD KEY `idx_refund_processing` (`status`, `updated_at`, `id`);
