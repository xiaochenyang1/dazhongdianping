-- Non-destructive migration for daily check-in.
-- Run once after 05_comment_governance_migration.sql on existing databases.
-- Fresh installs already include this table in 01_schema.sql.

CREATE TABLE IF NOT EXISTS `user_check_in` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `check_in_date` DATE NOT NULL,
  `streak_days` INT NOT NULL DEFAULT 1,
  `growth_value` INT NOT NULL DEFAULT 0,
  `points` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_check_in_date` (`user_id`, `check_in_date`),
  KEY `idx_user_check_in_user` (`user_id`, `check_in_date`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
