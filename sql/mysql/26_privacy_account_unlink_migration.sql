-- A deleted account must not collapse to user 0 under composite UNIQUE keys.
-- NULL detaches retained records while allowing several accounts to be deleted.
ALTER TABLE `conversation`
  MODIFY COLUMN `user_a` BIGINT NULL,
  MODIFY COLUMN `user_b` BIGINT NULL;
ALTER TABLE `consult_session` MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `creator_task_claim` MODIFY COLUMN `user_id` BIGINT NULL;
ALTER TABLE `post_report` MODIFY COLUMN `reporter_user_id` BIGINT NULL;
ALTER TABLE `review_comment_report` MODIFY COLUMN `reporter_user_id` BIGINT NULL;
ALTER TABLE `post_comment_report` MODIFY COLUMN `reporter_user_id` BIGINT NULL;
ALTER TABLE `message_report` MODIFY COLUMN `reporter_user_id` BIGINT NULL;
ALTER TABLE `user_device` MODIFY COLUMN `device_uid` VARCHAR(128) NULL;

-- Completed tasks from older releases must receive the expanded cleanup once.
-- The runtime advances this marker only in the same transaction as domain cleanup.
ALTER TABLE `privacy_delete_task`
  ADD COLUMN `domain_cleanup_version` TINYINT NOT NULL DEFAULT 0,
  ADD KEY `idx_privacy_delete_task_cleanup` (`status`, `domain_cleanup_version`, `id`);
