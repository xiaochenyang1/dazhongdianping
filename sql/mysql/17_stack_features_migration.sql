-- 反刷单风控、个性化推荐、投诉纠纷、付费推广、在线咨询、问大家、排队候位七大特性的建表与必要配置种子。
-- 在已导入 01_schema.sql + 02_seed_data.sql 的库上执行一次，放在 16 号脚本之后。
-- 不回写 01_schema.sql。CREATE TABLE IF NOT EXISTS + 种子用 ON DUPLICATE KEY / no-op，可安全重跑。

-- ============ 个性化推荐（recommendation） ============
CREATE TABLE IF NOT EXISTS `user_behavior_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `event_type` TINYINT NOT NULL,
  `shop_id` BIGINT DEFAULT NULL,
  `category_id` BIGINT DEFAULT NULL,
  `keyword` VARCHAR(64) DEFAULT NULL,
  `weight` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_behavior_user` (`user_id`, `region`, `created_at`, `id`),
  KEY `idx_behavior_user_category` (`user_id`, `region`, `category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `recommendation_weight` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `affinity_weight` DECIMAL(5,2) NOT NULL DEFAULT 40.00,
  `quality_weight` DECIMAL(5,2) NOT NULL DEFAULT 25.00,
  `popularity_weight` DECIMAL(5,2) NOT NULL DEFAULT 20.00,
  `distance_weight` DECIMAL(5,2) NOT NULL DEFAULT 15.00,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_recommendation_weight_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 反刷单 / 反虚假点评风控（riskcontrol） ============
CREATE TABLE IF NOT EXISTS `risk_rule` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `rule_code` VARCHAR(64) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `scene` VARCHAR(32) NOT NULL,
  `action` TINYINT NOT NULL DEFAULT 2,
  `threshold` INT NOT NULL DEFAULT 0,
  `window_seconds` INT NOT NULL DEFAULT 0,
  `risk_score` INT NOT NULL DEFAULT 0,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `remark` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_risk_rule_region_code` (`region`, `rule_code`),
  KEY `idx_risk_rule_scene` (`region`, `scene`, `enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `risk_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `scene` VARCHAR(32) NOT NULL,
  `user_id` BIGINT DEFAULT NULL,
  `device_fingerprint` VARCHAR(128) DEFAULT NULL,
  `ip` VARCHAR(64) DEFAULT NULL,
  `biz_id` BIGINT DEFAULT NULL,
  `risk_score` INT NOT NULL DEFAULT 0,
  `decision` TINYINT NOT NULL DEFAULT 1,
  `hit_rules` VARCHAR(512) NOT NULL DEFAULT '',
  `reason` VARCHAR(512) NOT NULL DEFAULT '',
  `dispose_status` TINYINT NOT NULL DEFAULT 0,
  `dispose_remark` VARCHAR(255) NOT NULL DEFAULT '',
  `disposed_by` BIGINT DEFAULT NULL,
  `disposed_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_risk_event_region` (`region`, `created_at`, `id`),
  KEY `idx_risk_event_dispose` (`region`, `dispose_status`, `id`),
  KEY `idx_risk_event_user` (`region`, `user_id`, `scene`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `device_fingerprint` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `fingerprint` VARCHAR(128) NOT NULL,
  `user_count` INT NOT NULL DEFAULT 0,
  `risk_hit_count` INT NOT NULL DEFAULT 0,
  `blocked` TINYINT(1) NOT NULL DEFAULT 0,
  `last_user_id` BIGINT DEFAULT NULL,
  `first_seen_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_fingerprint` (`region`, `fingerprint`),
  KEY `idx_device_fingerprint_blocked` (`region`, `blocked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `device_fingerprint_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `fingerprint` VARCHAR(128) NOT NULL,
  `user_id` BIGINT NOT NULL,
  `first_seen_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_fingerprint_user` (`region`, `fingerprint`, `user_id`),
  KEY `idx_device_fingerprint_user` (`region`, `fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 投诉纠纷（complaint） ============
CREATE TABLE IF NOT EXISTS `complaint_ticket` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `ticket_no` VARCHAR(32) NOT NULL,
  `user_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL DEFAULT 0,
  `merchant_id` BIGINT NOT NULL DEFAULT 0,
  `order_id` BIGINT NOT NULL DEFAULT 0,
  `type` TINYINT NOT NULL DEFAULT 1,
  `title` VARCHAR(128) NOT NULL,
  `content` VARCHAR(2000) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `merchant_reply` VARCHAR(2000) NOT NULL DEFAULT '',
  `merchant_replied_at` DATETIME DEFAULT NULL,
  `resolution` VARCHAR(2000) NOT NULL DEFAULT '',
  `resolved_by` BIGINT NOT NULL DEFAULT 0,
  `resolved_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_complaint_ticket_no` (`ticket_no`),
  KEY `idx_complaint_user` (`user_id`, `region`, `status`, `id`),
  KEY `idx_complaint_admin` (`region`, `status`, `id`),
  KEY `idx_complaint_merchant` (`merchant_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `complaint_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `ticket_id` BIGINT NOT NULL,
  `actor_type` TINYINT NOT NULL,
  `actor_id` BIGINT NOT NULL DEFAULT 0,
  `action` TINYINT NOT NULL,
  `remark` VARCHAR(2000) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_complaint_log_ticket` (`ticket_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 商户付费推广 / CPC 竞价（adpromo） ============
CREATE TABLE IF NOT EXISTS `ad_campaign` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `merchant_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `slot_type` TINYINT NOT NULL DEFAULT 1,
  `keyword` VARCHAR(64) NOT NULL DEFAULT '',
  `bid_cpc` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `daily_budget` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `spent_today` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `spend_date` DATE DEFAULT NULL,
  `total_spent` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `audit_status` TINYINT NOT NULL DEFAULT 1,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_ad_campaign_serve` (`region`, `slot_type`, `audit_status`, `status`, `is_deleted`),
  KEY `idx_ad_campaign_merchant` (`merchant_id`, `region`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ad_click_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `campaign_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL DEFAULT 0,
  `cost` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ad_click_campaign` (`campaign_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 在线咨询（consult） ============
CREATE TABLE IF NOT EXISTS `consult_session` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `user_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL,
  `merchant_id` BIGINT NOT NULL,
  `last_message` VARCHAR(500) NOT NULL DEFAULT '',
  `last_message_at` DATETIME DEFAULT NULL,
  `user_unread` INT NOT NULL DEFAULT 0,
  `merchant_unread` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_consult_user_shop` (`user_id`, `shop_id`),
  KEY `idx_consult_user` (`user_id`, `region`, `updated_at`),
  KEY `idx_consult_merchant` (`merchant_id`, `region`, `updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `consult_message` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `session_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `sender_type` TINYINT NOT NULL,
  `sender_id` BIGINT NOT NULL,
  `content` VARCHAR(1000) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_consult_message_session` (`session_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 问大家 / 商户问答（qa） ============
CREATE TABLE IF NOT EXISTS `shop_question` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `content` VARCHAR(500) NOT NULL,
  `answer_count` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_question_shop` (`shop_id`, `region`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shop_answer` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `question_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `content` VARCHAR(500) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_answer_question` (`question_id`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 排队 / 取号 / 候位（waitlist） ============
CREATE TABLE IF NOT EXISTS `waitlist_entry` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `shop_id` BIGINT NOT NULL,
  `merchant_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `table_type` TINYINT NOT NULL DEFAULT 1,
  `party_size` INT NOT NULL DEFAULT 1,
  `queue_no` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `called_at` DATETIME DEFAULT NULL,
  `seated_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_waitlist_shop` (`shop_id`, `table_type`, `status`, `id`),
  KEY `idx_waitlist_user` (`user_id`, `region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============ 必要配置种子（幂等，重跑不覆盖运营已调整的值） ============
-- 推荐打分默认权重：无此行推荐打分器缺配置
INSERT INTO `recommendation_weight` (`region`, `affinity_weight`, `quality_weight`, `popularity_weight`, `distance_weight`) VALUES
  ('CN', 40.00, 25.00, 20.00, 15.00),
  ('EU', 40.00, 25.00, 20.00, 15.00)
ON DUPLICATE KEY UPDATE `region` = `region`;

-- 风控规则种子：无规则则风控引擎不生效（RiskEvaluationService 对异常 fail-open，静默放行）
INSERT INTO `risk_rule` (`region`, `rule_code`, `name`, `scene`, `action`, `threshold`, `window_seconds`, `risk_score`, `enabled`, `remark`) VALUES
  ('CN', 'review_freq', '点评高频提交', 'review_create', 2, 5, 3600, 40, 1, '同一用户 1 小时内提交超过 5 条点评转人审'),
  ('CN', 'review_duplicate', '批量相似点评', 'review_create', 3, 85, 0, 60, 1, '与本人历史点评文本相似度超过 85% 判定为刷单并拦截'),
  ('CN', 'device_multi_account', '设备多账号刷单', 'review_create', 2, 5, 0, 50, 1, '同一设备关联账号数超过 5 转人审'),
  ('CN', 'order_freq', '下单高频', 'trade_order', 2, 10, 600, 30, 1, '同一用户 10 分钟内下单超过 10 笔转人审'),
  ('CN', 'register_multi_account', '注册设备多账号', 'auth_register', 3, 5, 0, 70, 1, '同一设备关联账号数超过 5 时拦截新注册'),
  ('EU', 'review_freq', 'High-frequency reviews', 'review_create', 2, 5, 3600, 40, 1, 'More than 5 reviews within 1 hour goes to manual audit'),
  ('EU', 'review_duplicate', 'Duplicate review text', 'review_create', 3, 85, 0, 60, 1, 'Text similarity over 85% against own history is blocked as fake'),
  ('EU', 'device_multi_account', 'Multi-account device', 'review_create', 2, 5, 0, 50, 1, 'Device linked to more than 5 accounts goes to manual audit'),
  ('EU', 'order_freq', 'High-frequency orders', 'trade_order', 2, 10, 600, 30, 1, 'More than 10 orders within 10 minutes goes to manual audit'),
  ('EU', 'register_multi_account', 'Multi-account device on register', 'auth_register', 3, 5, 0, 70, 1, 'Blocks new registration when a device is linked to more than 5 accounts')
ON DUPLICATE KEY UPDATE `rule_code` = `rule_code`;

-- 风控后台权限（对应 data.sql 中 risk:event:read/write，未落库则风控看板不可访问）
INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`) VALUES
  ('risk:event:read', '查看风控事件与规则', 'audit', 1, 1),
  ('risk:event:write', '处置风控事件与规则', 'audit', 2, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);
