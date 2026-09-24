-- 本地生活经营、信任与内容运营表。
-- 在已导入 01_schema.sql + 02_seed_data.sql 的库上执行一次。
-- 不回写 01_schema.sql。优惠券模板表不在 MySQL 基线里，这里不改它。

ALTER TABLE `shop`
  ADD COLUMN `chinese_service` TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN `chinese_menu` TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN `accept_alipay` TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN `accept_wechat` TINYINT(1) NOT NULL DEFAULT 0;

ALTER TABLE `review`
  ADD COLUMN `helpful_count` INT NOT NULL DEFAULT 0 AFTER `comment_count`;

UPDATE `shop`
SET `chinese_service` = 1, `chinese_menu` = 1, `accept_alipay` = 1, `accept_wechat` = 1
WHERE `id` IN (10001, 20001);

CREATE TABLE IF NOT EXISTS `review_helpful_vote` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_helpful_vote` (`review_id`, `user_id`),
  KEY `idx_review_helpful_user` (`user_id`, `review_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `review_translation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `user_id` BIGINT NOT NULL,
  `target_lang` VARCHAR(8) NOT NULL,
  `content` VARCHAR(2000) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_translation_user` (`review_id`, `user_id`, `target_lang`),
  KEY `idx_review_translation_review` (`review_id`, `target_lang`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dish_review` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `dish_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `score` TINYINT NOT NULL,
  `content` VARCHAR(500) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_dish_review_dish` (`dish_id`, `region`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tax_rate` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `name` VARCHAR(64) NOT NULL,
  `rate_bp` INT NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tax_rate_region` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `invoice_title` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `title_type` TINYINT NOT NULL DEFAULT 1,
  `name` VARCHAR(128) NOT NULL,
  `tax_no` VARCHAR(64) NOT NULL DEFAULT '',
  `email` VARCHAR(128) NOT NULL DEFAULT '',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_invoice_title_user` (`user_id`, `region`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `invoice_request` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `user_id` BIGINT NOT NULL,
  `order_id` BIGINT NOT NULL,
  `title_id` BIGINT NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `tax_amount` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `status` TINYINT NOT NULL DEFAULT 1,
  `invoice_no` VARCHAR(64) NOT NULL DEFAULT '',
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_invoice_request_order` (`order_id`),
  KEY `idx_invoice_request_user` (`user_id`, `region`, `status`, `id`),
  KEY `idx_invoice_request_admin` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `automod_hit` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `biz_type` VARCHAR(32) NOT NULL,
  `biz_id` BIGINT NOT NULL DEFAULT 0,
  `user_id` BIGINT NOT NULL DEFAULT 0,
  `decision` TINYINT NOT NULL,
  `provider` VARCHAR(32) NOT NULL DEFAULT '',
  `reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_automod_hit_region` (`region`, `decision`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `seckill_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `merchant_id` BIGINT NOT NULL,
  `deal_id` BIGINT NOT NULL DEFAULT 0,
  `title` VARCHAR(128) NOT NULL,
  `seckill_price` DECIMAL(10,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `stock` INT NOT NULL DEFAULT 0,
  `sold` INT NOT NULL DEFAULT 0,
  `start_at` DATETIME NOT NULL,
  `end_at` DATETIME NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `audit_status` TINYINT NOT NULL DEFAULT 1,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_seckill_region` (`region`, `audit_status`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `seckill_claim` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `event_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seckill_claim` (`event_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `groupbuy_campaign` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `merchant_id` BIGINT NOT NULL,
  `deal_id` BIGINT NOT NULL DEFAULT 0,
  `title` VARCHAR(128) NOT NULL,
  `group_price` DECIMAL(10,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `group_size` INT NOT NULL DEFAULT 2,
  `start_at` DATETIME NOT NULL,
  `end_at` DATETIME NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `audit_status` TINYINT NOT NULL DEFAULT 1,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_groupbuy_campaign_region` (`region`, `audit_status`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `groupbuy_team` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `campaign_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `leader_user_id` BIGINT NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `member_count` INT NOT NULL DEFAULT 1,
  `expire_at` DATETIME NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_groupbuy_team_campaign` (`campaign_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `groupbuy_member` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `team_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_groupbuy_member` (`team_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guide_article` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `city_id` BIGINT NOT NULL DEFAULT 0,
  `title` VARCHAR(128) NOT NULL,
  `summary` VARCHAR(500) NOT NULL DEFAULT '',
  `cover_url` VARCHAR(255) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_guide_article_region` (`region`, `status`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guide_section` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `article_id` BIGINT NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  `heading` VARCHAR(128) NOT NULL DEFAULT '',
  `body` VARCHAR(4000) NOT NULL DEFAULT '',
  `shop_id` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_guide_section_article` (`article_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `creator_task` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `title` VARCHAR(128) NOT NULL,
  `description` VARCHAR(1000) NOT NULL DEFAULT '',
  `reward_points` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_creator_task_region` (`region`, `status`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `creator_task_claim` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `task_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_creator_task_claim` (`task_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `feature_flag` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `flag_key` VARCHAR(64) NOT NULL,
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `rollout_percent` INT NOT NULL DEFAULT 100,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_feature_flag` (`region`, `flag_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `experiment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `name` VARCHAR(128) NOT NULL,
  `flag_key` VARCHAR(64) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_experiment_region` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `experiment_assignment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `experiment_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `variant` VARCHAR(16) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_experiment_assignment` (`experiment_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `support_ticket` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `requester_type` TINYINT NOT NULL,
  `requester_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL DEFAULT 0,
  `subject` VARCHAR(128) NOT NULL,
  `content` VARCHAR(2000) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_support_ticket_requester` (`requester_type`, `requester_id`, `region`, `id`),
  KEY `idx_support_ticket_admin` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ticket_message` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `ticket_id` BIGINT NOT NULL,
  `sender_type` TINYINT NOT NULL,
  `sender_id` BIGINT NOT NULL DEFAULT 0,
  `content` VARCHAR(2000) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ticket_message_ticket` (`ticket_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `open_app` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `name` VARCHAR(128) NOT NULL,
  `owner_merchant_id` BIGINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_open_app_region` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `open_api_key` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `app_id` BIGINT NOT NULL,
  `key_id` VARCHAR(40) NOT NULL,
  `secret_hash` VARCHAR(128) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_open_api_key` (`key_id`),
  KEY `idx_open_api_key_app` (`app_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `message_outbox` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT '',
  `topic` VARCHAR(64) NOT NULL,
  `payload` VARCHAR(4000) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `published_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  KEY `idx_message_outbox_status` (`status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tax_rate` (`region`, `name`, `rate_bp`, `status`)
SELECT 'CN', '餐饮服务增值税', 600, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `tax_rate` WHERE `region` = 'CN' AND `name` = '餐饮服务增值税');

INSERT INTO `tax_rate` (`region`, `name`, `rate_bp`, `status`)
SELECT 'EU', 'Standard VAT', 2000, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `tax_rate` WHERE `region` = 'EU' AND `name` = 'Standard VAT');

INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`) VALUES
  ('finance:invoice:read', '查看发票与税率', 'finance', 1, 1),
  ('finance:invoice:write', '审核发票与税率', 'finance', 2, 1),
  ('audit:automod:read', '查看机审命中', 'audit', 1, 1),
  ('audit:automod:write', '处置机审命中', 'audit', 2, 1),
  ('operations:guide:read', '查看攻略', 'operations', 1, 1),
  ('operations:guide:write', '维护攻略', 'operations', 2, 1),
  ('operations:creator:read', '查看创作者任务', 'operations', 1, 1),
  ('operations:creator:write', '维护创作者任务', 'operations', 2, 1),
  ('operations:experiment:read', '查看实验与开关', 'operations', 1, 1),
  ('operations:experiment:write', '维护实验与开关', 'operations', 2, 1),
  ('support:ticket:read', '查看客服工单', 'support', 1, 1),
  ('support:ticket:write', '处理客服工单', 'support', 2, 1),
  ('openapi:read', '查看开放平台应用', 'system', 1, 1),
  ('openapi:write', '维护开放平台应用', 'system', 2, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'finance:invoice:read', 'finance:invoice:write',
  'audit:automod:read', 'audit:automod:write',
  'operations:guide:read', 'operations:guide:write',
  'operations:creator:read', 'operations:creator:write',
  'operations:experiment:read', 'operations:experiment:write',
  'support:ticket:read', 'support:ticket:write',
  'openapi:read', 'openapi:write'
)
WHERE r.`code` = 'super_admin';

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'audit:automod:read', 'audit:automod:write', 'support:ticket:read', 'support:ticket:write'
)
WHERE r.`code` = 'content_auditor';

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN ('finance:invoice:read', 'finance:invoice:write')
WHERE r.`code` = 'merchant_auditor';

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'operations:guide:read', 'operations:guide:write',
  'operations:creator:read', 'operations:creator:write',
  'operations:experiment:read', 'operations:experiment:write'
)
WHERE r.`code` = 'operations_manager';

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN ('openapi:read', 'openapi:write')
WHERE r.`code` = 'data_operator';

UPDATE `merchant_role`
SET `permissions` = CONCAT(`permissions`, ',marketing:view,marketing:manage,analytics:view,ticket:view,ticket:reply')
WHERE `code` IN ('owner', 'store_manager')
  AND `permissions` NOT LIKE '%marketing:view%';

UPDATE `merchant_role`
SET `permissions` = CONCAT(`permissions`, ',ticket:view,ticket:reply')
WHERE `code` = 'service_operator'
  AND `permissions` NOT LIKE '%ticket:view%';
