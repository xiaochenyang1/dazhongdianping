-- Non-destructive migration for review and post comment governance.
-- Run once after 04_admin_import_batch_scope_migration.sql on existing databases.
-- Fresh installs already include these columns and tables in 01_schema.sql.

ALTER TABLE `review_comment`
  ADD COLUMN `audit_remark` VARCHAR(255) NOT NULL DEFAULT '' AFTER `status`;

ALTER TABLE `post_comment`
  ADD COLUMN `audit_remark` VARCHAR(255) NOT NULL DEFAULT '' AFTER `status`;

CREATE TABLE IF NOT EXISTS `review_comment_report` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `review_id` BIGINT NOT NULL,
  `comment_id` BIGINT NOT NULL,
  `reporter_user_id` BIGINT NOT NULL,
  `reporter_user_name` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(200) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  KEY `idx_review_comment_report_comment` (`comment_id`, `status`, `is_deleted`, `id`),
  UNIQUE KEY `uk_review_comment_report_user` (`comment_id`, `reporter_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `post_comment_report` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `post_id` BIGINT NOT NULL,
  `comment_id` BIGINT NOT NULL,
  `reporter_user_id` BIGINT NOT NULL,
  `reporter_user_name` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(200) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  KEY `idx_post_comment_report_comment` (`comment_id`, `status`, `is_deleted`, `id`),
  UNIQUE KEY `uk_post_comment_report_user` (`comment_id`, `reporter_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
