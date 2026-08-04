-- Non-destructive migration for the points mall.
-- Run once after 06_daily_check_in_migration.sql on existing databases.
-- Fresh installs already include these tables in 01_schema.sql.

CREATE TABLE IF NOT EXISTS `points_product` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `cover_image` VARCHAR(255) NOT NULL DEFAULT '',
  `description` VARCHAR(500) NOT NULL DEFAULT '',
  `points_price` INT NOT NULL,
  `stock` INT NOT NULL DEFAULT 0,
  `exchange_limit_per_user` INT NOT NULL DEFAULT 0,
  `exchange_count` INT NOT NULL DEFAULT 0,
  `fulfill_type` TINYINT NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 1,
  `sort` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  KEY `idx_points_product_region_status` (`region`, `status`, `is_deleted`, `sort`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `points_exchange` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `product_id` BIGINT NOT NULL,
  `product_name` VARCHAR(64) NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `points_cost` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 0,
  `redeem_code` VARCHAR(32) NOT NULL,
  `remark` VARCHAR(255) NOT NULL DEFAULT '',
  `fulfilled_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_points_exchange_redeem_code` (`redeem_code`),
  KEY `idx_points_exchange_user` (`user_id`, `created_at`, `id`),
  KEY `idx_points_exchange_product` (`product_id`, `created_at`, `id`),
  KEY `idx_points_exchange_region_status` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
