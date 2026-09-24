-- 营销券模板、用户券，以及订单上的券抵扣字段。
-- 在已导入 01_schema.sql + 02_seed_data.sql 的库上执行一次，放在 15 号脚本之后。
-- 不回写 01_schema.sql。ALTER 不能重复执行。

ALTER TABLE `order`
  ADD COLUMN `original_amount` DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER `unit_price`,
  ADD COLUMN `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER `original_amount`,
  ADD COLUMN `user_coupon_id` BIGINT UNSIGNED NULL AFTER `discount_amount`;

CREATE TABLE IF NOT EXISTS `marketing_coupon_template` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `name` VARCHAR(128) NOT NULL,
  `type` TINYINT NOT NULL DEFAULT 1,
  `threshold_amount` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `shop_id` BIGINT NOT NULL DEFAULT 0,
  `merchant_id` BIGINT NOT NULL DEFAULT 0,
  `audit_status` TINYINT NOT NULL DEFAULT 2,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `total_quantity` INT NOT NULL DEFAULT 0,
  `claimed_quantity` INT NOT NULL DEFAULT 0,
  `per_user_limit` INT NOT NULL DEFAULT 1,
  `valid_days` INT NOT NULL DEFAULT 7,
  `claim_start` DATETIME DEFAULT NULL,
  `claim_end` DATETIME DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_coupon_template_region` (`region`, `status`, `is_deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_coupon` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `template_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `type` TINYINT NOT NULL DEFAULT 1,
  `threshold_amount` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `shop_id` BIGINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `used_order_id` BIGINT DEFAULT NULL,
  `used_at` DATETIME DEFAULT NULL,
  `expire_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_coupon_owner` (`user_id`, `region`, `status`, `id`),
  KEY `idx_user_coupon_template` (`user_id`, `template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `marketing_coupon_template`
  (`id`, `region`, `name`, `type`, `threshold_amount`, `discount_amount`, `currency`, `shop_id`, `total_quantity`, `claimed_quantity`, `per_user_limit`, `valid_days`, `status`)
VALUES
  (5001, 'CN', '满100减20', 1, 100.00, 20.00, 'CNY', 0, 1000, 0, 1, 30, 1),
  (5002, 'CN', '满50减8', 1, 50.00, 8.00, 'CNY', 0, 0, 0, 3, 15, 1),
  (5003, 'CN', '新客立减15', 2, 0.00, 15.00, 'CNY', 0, 5000, 0, 1, 7, 1),
  (5011, 'EU', 'Spend 100 save 20', 1, 100.00, 20.00, 'EUR', 0, 1000, 0, 1, 30, 1),
  (5012, 'EU', 'Spend 50 save 8', 1, 50.00, 8.00, 'EUR', 0, 0, 0, 3, 15, 1),
  (5013, 'EU', 'New customer save 15', 2, 0.00, 15.00, 'EUR', 0, 5000, 0, 1, 7, 1);
