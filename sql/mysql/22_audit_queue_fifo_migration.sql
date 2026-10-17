-- Keep regional pending moderation queues ordered by their oldest submission.
ALTER TABLE `audit_task`
  ADD INDEX `idx_audit_task_region_queue_order` (`region`, `biz_type`, `status`, `created_at`, `id`);
