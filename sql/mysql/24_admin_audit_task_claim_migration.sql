ALTER TABLE `audit_task`
  ADD COLUMN `claimed_by_admin_id` BIGINT DEFAULT NULL AFTER `auditor_id`,
  ADD COLUMN `claimed_at` DATETIME DEFAULT NULL AFTER `claimed_by_admin_id`,
  ADD COLUMN `claim_expires_at` DATETIME DEFAULT NULL AFTER `claimed_at`,
  ADD INDEX `idx_audit_task_claim` (`region`, `biz_type`, `status`, `claimed_by_admin_id`, `claim_expires_at`);
