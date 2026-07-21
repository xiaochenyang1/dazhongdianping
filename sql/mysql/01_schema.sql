-- WARNING:
-- This script recreates the local MySQL schema used by the current codebase.
-- Run it only on a database that can be reset safely.
-- Coverage:
-- - Current code MySQL schema for the implemented M1-M7 local closure
-- - Includes privacy center, merchant RBAC/workbench, unified audit center and local expert certification

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `admin_region_scope`;
DROP TABLE IF EXISTS `admin_role_permission`;
DROP TABLE IF EXISTS `admin_user_role`;
DROP TABLE IF EXISTS `admin_permission`;
DROP TABLE IF EXISTS `admin_role`;
DROP TABLE IF EXISTS `admin_user`;
DROP TABLE IF EXISTS `import_batch`;
DROP TABLE IF EXISTS `user_session`;
DROP TABLE IF EXISTS `verification_code`;
DROP TABLE IF EXISTS `search_history`;
DROP TABLE IF EXISTS `growth_points_log`;
DROP TABLE IF EXISTS `user_device`;
DROP TABLE IF EXISTS `user_policy_accept_log`;
DROP TABLE IF EXISTS `privacy_delete_task`;
DROP TABLE IF EXISTS `privacy_export_task`;
DROP TABLE IF EXISTS `user_expert_certification`;
DROP TABLE IF EXISTS `app_user`;
DROP TABLE IF EXISTS `audit_log`;
DROP TABLE IF EXISTS `audit_task`;
DROP TABLE IF EXISTS `merchant_review_appeal`;
DROP TABLE IF EXISTS `review_merchant_reply`;
DROP TABLE IF EXISTS `review_report`;
DROP TABLE IF EXISTS `review_comment`;
DROP TABLE IF EXISTS `review_like`;
DROP TABLE IF EXISTS `review_image`;
DROP TABLE IF EXISTS `review`;
DROP TABLE IF EXISTS `operation_activity_item`;
DROP TABLE IF EXISTS `operation_activity`;
DROP TABLE IF EXISTS `hot_keyword`;
DROP TABLE IF EXISTS `home_feed`;
DROP TABLE IF EXISTS `home_banner`;
DROP TABLE IF EXISTS `merchant_shop_change_dish`;
DROP TABLE IF EXISTS `merchant_shop_change_photo`;
DROP TABLE IF EXISTS `merchant_shop_change`;
DROP TABLE IF EXISTS `dish`;
DROP TABLE IF EXISTS `shop_photo`;
DROP TABLE IF EXISTS `shop`;
DROP TABLE IF EXISTS `merchant`;
DROP TABLE IF EXISTS `area`;
DROP TABLE IF EXISTS `city`;
DROP TABLE IF EXISTS `category`;

CREATE TABLE `category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `parent_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_region_parent_name` (`region`, `parent_id`, `name`),
  KEY `idx_category_region_status_parent_sort` (`region`, `status`, `parent_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `city` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(32) NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_city_region_code` (`region`, `code`),
  UNIQUE KEY `uk_city_region_name` (`region`, `name`),
  KEY `idx_city_region_status_sort` (`region`, `status`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `area` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `city_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_area_region_city_name` (`region`, `city_id`, `name`),
  KEY `idx_area_region_city_status_sort` (`region`, `city_id`, `status`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `account` VARCHAR(64) NOT NULL,
  `password_hash` VARCHAR(100) NOT NULL,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `last_login_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_user_account` (`account`),
  KEY `idx_admin_user_status` (`status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_role` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `built_in` TINYINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_role_code` (`code`),
  KEY `idx_admin_role_status` (`status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_permission` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(96) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `category` VARCHAR(32) NOT NULL,
  `permission_type` TINYINT NOT NULL DEFAULT 3,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_permission_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_user_role` (
  `admin_id` BIGINT NOT NULL,
  `role_id` BIGINT NOT NULL,
  PRIMARY KEY (`admin_id`, `role_id`),
  KEY `idx_admin_user_role_role` (`role_id`, `admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_role_permission` (
  `role_id` BIGINT NOT NULL,
  `permission_id` BIGINT NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  KEY `idx_admin_role_permission_permission` (`permission_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admin_region_scope` (
  `admin_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  PRIMARY KEY (`admin_id`, `region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `account` VARCHAR(128) NOT NULL,
  `company_name` VARCHAR(128) NOT NULL,
  `contact_name` VARCHAR(64) NOT NULL DEFAULT '',
  `contact_phone` VARCHAR(32) NOT NULL DEFAULT '',
  `region` VARCHAR(8) NOT NULL,
  `audit_status` TINYINT NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_account` (`account`),
  KEY `idx_merchant_region_status` (`region`, `status`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_operator` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL,
  `account` VARCHAR(128) NOT NULL,
  `password_hash` VARCHAR(100) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `phone` VARCHAR(32) NOT NULL DEFAULT '',
  `email` VARCHAR(128) NOT NULL DEFAULT '',
  `operator_type` TINYINT NOT NULL DEFAULT 2,
  `shop_scope_type` TINYINT NOT NULL DEFAULT 2,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_operator_account` (`account`),
  KEY `idx_merchant_operator_merchant_status` (`merchant_id`, `status`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_role` (
  `id` BIGINT NOT NULL,
  `code` VARCHAR(32) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `permissions` VARCHAR(1000) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_operator_role` (
  `operator_id` BIGINT NOT NULL,
  `role_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_merchant_operator_role` (`operator_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_operator_shop` (
  `operator_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_merchant_operator_shop` (`operator_id`, `shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_application` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL,
  `license_url` VARCHAR(255) NOT NULL DEFAULT '',
  `legal_person` VARCHAR(64) NOT NULL DEFAULT '',
  `shop_photo_urls` VARCHAR(2000) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 0,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `audit_by` BIGINT NOT NULL DEFAULT 0,
  `submitted_at` DATETIME NULL,
  `audited_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_application_merchant` (`merchant_id`),
  KEY `idx_merchant_application_status` (`status`, `updated_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_operation_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL,
  `operator_id` BIGINT NOT NULL,
  `action` VARCHAR(64) NOT NULL,
  `target_type` VARCHAR(32) NOT NULL DEFAULT '',
  `target_id` BIGINT NOT NULL DEFAULT 0,
  `detail` VARCHAR(1000) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_merchant_operation_log_merchant` (`merchant_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_shop_change` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL,
  `operator_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `change_type` TINYINT NOT NULL,
  `target_shop_id` BIGINT NOT NULL DEFAULT 0,
  `base_updated_at` DATETIME NULL,
  `category_id` BIGINT NOT NULL DEFAULT 0,
  `city_id` BIGINT NOT NULL DEFAULT 0,
  `area_id` BIGINT NOT NULL DEFAULT 0,
  `name` VARCHAR(128) NOT NULL DEFAULT '',
  `cover_url` VARCHAR(255) NOT NULL DEFAULT '',
  `phone` VARCHAR(64) NOT NULL DEFAULT '',
  `price_per_capita` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `address` VARCHAR(255) NOT NULL DEFAULT '',
  `latitude` DECIMAL(10,7) NULL,
  `longitude` DECIMAL(10,7) NULL,
  `business_hours` VARCHAR(128) NOT NULL DEFAULT '',
  `summary` VARCHAR(255) NOT NULL DEFAULT '',
  `open_now` TINYINT(1) NOT NULL DEFAULT 1,
  `tags` VARCHAR(255) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 0,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `audit_by` BIGINT NOT NULL DEFAULT 0,
  `submitted_at` DATETIME NULL,
  `audited_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_shop_change_merchant_status` (`merchant_id`,`region`,`status`,`id`),
  KEY `idx_shop_change_target_status` (`target_shop_id`,`status`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_shop_change_photo` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `change_id` BIGINT NOT NULL,
  `image_url` VARCHAR(255) NOT NULL,
  `photo_type` TINYINT NOT NULL DEFAULT 1,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_change_photo` (`change_id`,`sort_no`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_shop_change_dish` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `change_id` BIGINT NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `recommend_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_change_dish` (`change_id`,`sort_no`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `shop` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL DEFAULT 0,
  `category_id` BIGINT NOT NULL,
  `city_id` BIGINT NOT NULL,
  `area_id` BIGINT NOT NULL,
  `latitude` DECIMAL(10,7) NULL,
  `longitude` DECIMAL(10,7) NULL,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `cover_url` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(64) NOT NULL DEFAULT '',
  `score` DECIMAL(3,1) NOT NULL,
  `taste_score` DECIMAL(3,1) NOT NULL,
  `env_score` DECIMAL(3,1) NOT NULL,
  `service_score` DECIMAL(3,1) NOT NULL,
  `review_count` INT NOT NULL DEFAULT 0,
  `price_per_capita` DECIMAL(10,2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `address` VARCHAR(255) NOT NULL,
  `business_hours` VARCHAR(128) NOT NULL,
  `summary` VARCHAR(255) NOT NULL,
  `has_deal` TINYINT(1) NOT NULL DEFAULT 0,
  `open_now` TINYINT(1) NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `tags` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_shop_region_status_city_category` (`region`, `status`, `is_deleted`, `city_id`, `category_id`, `id`),
  KEY `idx_shop_region_city_area` (`region`, `city_id`, `area_id`, `id`),
  KEY `idx_shop_merchant_id` (`merchant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `shop_view_daily` (
  `shop_id` BIGINT NOT NULL,
  `biz_date` DATE NOT NULL,
  `view_count` BIGINT NOT NULL DEFAULT 0,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_shop_view_daily` (`shop_id`, `biz_date`),
  KEY `idx_shop_view_daily_date` (`biz_date`, `shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `shop_photo` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `shop_id` BIGINT NOT NULL,
  `image_url` VARCHAR(255) NOT NULL,
  `photo_type` TINYINT NOT NULL DEFAULT 1,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_photo_shop_sort` (`shop_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `dish` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `shop_id` BIGINT NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `recommend_reason` VARCHAR(255) NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_dish_shop_sort` (`shop_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `home_banner` (
  `id` BIGINT NOT NULL,
  `city_id` BIGINT DEFAULT NULL,
  `region` VARCHAR(8) NOT NULL,
  `title` VARCHAR(128) NOT NULL,
  `subtitle` VARCHAR(255) DEFAULT NULL,
  `image_url` VARCHAR(255) NOT NULL,
  `link_url` VARCHAR(255) NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_home_banner_region_city_enabled_sort` (`region`, `enabled`, `city_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hot_keyword` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL,
  `keyword` VARCHAR(64) NOT NULL,
  `sort` INT NOT NULL DEFAULT 0,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_hot_keyword_region_enabled_sort` (`region`, `enabled`, `sort`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `operation_activity` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(128) NOT NULL,
  `code` VARCHAR(64) NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `city_id` BIGINT NOT NULL DEFAULT 0,
  `channel` TINYINT NOT NULL DEFAULT 1,
  `type` TINYINT NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 0,
  `cover` VARCHAR(255) NOT NULL DEFAULT '',
  `landing_url` VARCHAR(255) NOT NULL DEFAULT '',
  `rule_json` VARCHAR(2000) NOT NULL DEFAULT '{}',
  `start_at` DATETIME DEFAULT NULL,
  `end_at` DATETIME DEFAULT NULL,
  `created_by` BIGINT NOT NULL DEFAULT 0,
  `updated_by` BIGINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_operation_activity_code` (`code`),
  KEY `idx_operation_activity_region_city_status` (`region`, `city_id`, `status`, `start_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `operation_activity_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `activity_id` BIGINT NOT NULL,
  `target_type` TINYINT NOT NULL,
  `target_id` BIGINT NOT NULL DEFAULT 0,
  `title` VARCHAR(128) NOT NULL DEFAULT '',
  `subtitle` VARCHAR(255) NOT NULL DEFAULT '',
  `image` VARCHAR(255) NOT NULL DEFAULT '',
  `sort` INT NOT NULL DEFAULT 0,
  `extra_json` VARCHAR(2000) NOT NULL DEFAULT '{}',
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_operation_activity_item_target` (`activity_id`, `target_type`, `target_id`),
  KEY `idx_operation_activity_item_sort` (`activity_id`, `status`, `sort`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `home_feed` (
  `id` BIGINT NOT NULL,
  `city_id` BIGINT DEFAULT NULL,
  `shop_id` BIGINT DEFAULT NULL,
  `region` VARCHAR(8) NOT NULL,
  `feed_type` VARCHAR(32) NOT NULL,
  `title` VARCHAR(128) NOT NULL,
  `subtitle` VARCHAR(255) DEFAULT NULL,
  `cover_url` VARCHAR(255) NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_home_feed_region_city_enabled_sort` (`region`, `enabled`, `city_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL DEFAULT 0,
  `shop_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `user_name` VARCHAR(64) NOT NULL,
  `content` VARCHAR(500) NOT NULL,
  `score_overall` DECIMAL(3,1) NOT NULL,
  `score_taste` DECIMAL(3,1) NOT NULL DEFAULT 0,
  `score_env` DECIMAL(3,1) NOT NULL DEFAULT 0,
  `score_service` DECIMAL(3,1) NOT NULL DEFAULT 0,
  `cost` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `currency` CHAR(3) NOT NULL DEFAULT 'CNY',
  `like_count` INT NOT NULL DEFAULT 0,
  `comment_count` INT NOT NULL DEFAULT 0,
  `audit_status` TINYINT NOT NULL DEFAULT 0,
  `audit_remark` VARCHAR(255) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `tags` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_review_shop_public` (`shop_id`, `audit_status`, `status`, `is_deleted`, `created_at`, `id`),
  KEY `idx_review_user_id` (`user_id`, `is_deleted`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review_image` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `url` VARCHAR(255) NOT NULL,
  `media_type` TINYINT NOT NULL DEFAULT 1,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_review_image_review_id` (`review_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review_like` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_like_review_user` (`review_id`, `user_id`),
  KEY `idx_review_like_review_id` (`review_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review_comment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `user_name` VARCHAR(64) NOT NULL,
  `content` VARCHAR(300) NOT NULL,
  `parent_id` BIGINT NOT NULL DEFAULT 0,
  `reply_to` BIGINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_review_comment_review_id` (`review_id`, `status`, `is_deleted`, `parent_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review_report` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `reporter_user_id` BIGINT NOT NULL,
  `reporter_user_name` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(200) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_review_report_review_id` (`review_id`, `status`, `is_deleted`, `id`),
  KEY `idx_review_report_user_id` (`reporter_user_id`, `review_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `review_merchant_reply` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `review_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL,
  `merchant_id` BIGINT NOT NULL,
  `operator_id` BIGINT NOT NULL,
  `content` VARCHAR(500) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_merchant_reply_review` (`review_id`),
  KEY `idx_review_merchant_reply_shop` (`shop_id`, `updated_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `merchant_review_appeal` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `merchant_id` BIGINT NOT NULL,
  `operator_id` BIGINT NOT NULL,
  `review_id` BIGINT NOT NULL,
  `shop_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `base_review_updated_at` DATETIME NULL,
  `reason` VARCHAR(500) NOT NULL DEFAULT '',
  `evidence_urls` VARCHAR(2000) NOT NULL DEFAULT '[]',
  `status` TINYINT NOT NULL DEFAULT 0,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `audit_by` BIGINT NOT NULL DEFAULT 0,
  `submitted_at` DATETIME NULL,
  `audited_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_merchant_review_appeal` (`merchant_id`, `review_id`),
  KEY `idx_merchant_review_appeal_status` (`merchant_id`, `region`, `status`, `id`),
  KEY `idx_merchant_review_appeal_shop` (`shop_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `user_name` VARCHAR(64) NOT NULL,
  `title` VARCHAR(80) NOT NULL,
  `content` VARCHAR(5000) NOT NULL,
  `content_type` TINYINT NOT NULL DEFAULT 1,
  `shop_id` BIGINT DEFAULT NULL,
  `deal_id` BIGINT DEFAULT NULL,
  `like_count` INT NOT NULL DEFAULT 0,
  `comment_count` INT NOT NULL DEFAULT 0,
  `repost_count` INT NOT NULL DEFAULT 0,
  `audit_status` TINYINT NOT NULL DEFAULT 0,
  `audit_remark` VARCHAR(255) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_post_public` (`region`, `audit_status`, `status`, `is_deleted`, `created_at`, `id`),
  KEY `idx_post_user` (`user_id`, `region`, `is_deleted`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_image` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `url` VARCHAR(255) NOT NULL,
  `sort_no` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_post_image_post` (`post_id`, `sort_no`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `topic` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `post_count` INT NOT NULL DEFAULT 0,
  `follower_count` INT NOT NULL DEFAULT 0,
  `recommended` TINYINT(1) NOT NULL DEFAULT 0,
  `pinned_sort` INT NOT NULL DEFAULT 0,
  `merged_to_id` BIGINT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_topic_region_name` (`region`, `name`),
  KEY `idx_topic_region_public` (`region`, `status`, `merged_to_id`, `recommended`, `pinned_sort`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_topic` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `topic_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_topic` (`post_id`, `topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `topic_follow` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `topic_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_topic_follow` (`topic_id`, `user_id`),
  KEY `idx_topic_follow_user` (`user_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `topic_hot_snapshot` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `topic_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `score` BIGINT NOT NULL DEFAULT 0,
  `post_count_7d` INT NOT NULL DEFAULT 0,
  `like_count_7d` INT NOT NULL DEFAULT 0,
  `comment_count_7d` INT NOT NULL DEFAULT 0,
  `calculated_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_topic_hot_snapshot` (`topic_id`),
  KEY `idx_topic_hot_region_score` (`region`, `score`, `topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_like` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_like` (`post_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_repost` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_repost_user` (`post_id`, `user_id`),
  KEY `idx_post_repost_user` (`user_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_comment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `user_name` VARCHAR(64) NOT NULL,
  `content` VARCHAR(500) NOT NULL,
  `parent_id` BIGINT NOT NULL DEFAULT 0,
  `reply_to` BIGINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_post_comment_post` (`post_id`, `status`, `is_deleted`, `parent_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `post_report` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `post_id` BIGINT NOT NULL,
  `reporter_user_id` BIGINT NOT NULL,
  `reporter_user_name` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(200) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_report_user` (`post_id`, `reporter_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `audit_task` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `biz_type` TINYINT NOT NULL,
  `biz_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `machine_result` TINYINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 0,
  `auditor_id` BIGINT NOT NULL DEFAULT 0,
  `remark` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_task_region_status` (`region`, `biz_type`, `status`, `id`),
  KEY `idx_audit_task_biz_status` (`biz_type`, `biz_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `audit_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `admin_id` BIGINT NOT NULL,
  `action` VARCHAR(64) NOT NULL,
  `target` VARCHAR(64) NOT NULL DEFAULT '',
  `detail` VARCHAR(1000) NOT NULL DEFAULT '',
  `ip` VARCHAR(45) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_log_admin` (`admin_id`, `created_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `privacy_export_task` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `scope_json` LONGTEXT NOT NULL,
  `format` VARCHAR(16) NOT NULL DEFAULT 'zip',
  `status` TINYINT NOT NULL DEFAULT 0,
  `file_name` VARCHAR(255) NOT NULL DEFAULT '',
  `file_path` VARCHAR(512) NOT NULL DEFAULT '',
  `expire_at` DATETIME DEFAULT NULL,
  `fail_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_privacy_export_task_user_created` (`user_id`, `created_at`, `id`),
  KEY `idx_privacy_export_task_user_status` (`user_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `privacy_delete_task` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `verify_type` VARCHAR(16) NOT NULL,
  `account_snapshot` VARCHAR(128) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `cooling_off_expire_at` DATETIME NOT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  `cancelled_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_privacy_delete_task_user_created` (`user_id`, `created_at`, `id`),
  KEY `idx_privacy_delete_task_user_status` (`user_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_policy_accept_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `policy_type` TINYINT NOT NULL,
  `version` VARCHAR(32) NOT NULL,
  `locale` VARCHAR(16) NOT NULL DEFAULT 'zh-CN',
  `source` TINYINT NOT NULL DEFAULT 1,
  `request_ip` VARCHAR(45) NOT NULL DEFAULT '',
  `user_agent` VARCHAR(255) NOT NULL DEFAULT '',
  `accepted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_policy_accept_user_type` (`user_id`, `policy_type`, `id`),
  KEY `idx_policy_accept_type_version` (`policy_type`, `version`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_device` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `device_uid` VARCHAR(128) NOT NULL,
  `platform` TINYINT NOT NULL,
  `push_channel` TINYINT NOT NULL DEFAULT 0,
  `push_token` VARCHAR(255) NOT NULL DEFAULT '',
  `app_version` VARCHAR(32) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `last_active_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_device_uid` (`device_uid`),
  KEY `idx_user_device_user_status` (`user_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `app_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `nickname` VARCHAR(64) NOT NULL DEFAULT '',
  `avatar` VARCHAR(255) NOT NULL DEFAULT '',
  `email` VARCHAR(128) DEFAULT NULL,
  `phone` VARCHAR(32) DEFAULT NULL,
  `password_hash` VARCHAR(100) DEFAULT NULL,
  `gender` TINYINT NOT NULL DEFAULT 0,
  `signature` VARCHAR(255) NOT NULL DEFAULT '',
  `preferred_region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `growth_value` INT NOT NULL DEFAULT 0,
  `level` TINYINT NOT NULL DEFAULT 1,
  `points` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `last_login_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_user_email` (`email`),
  UNIQUE KEY `uk_app_user_phone` (`phone`),
  KEY `idx_app_user_status` (`status`, `is_deleted`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_expert_certification` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `reason` VARCHAR(500) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 1,
  `reject_reason` VARCHAR(255) NOT NULL DEFAULT '',
  `audit_by` BIGINT NOT NULL DEFAULT 0,
  `submitted_at` DATETIME DEFAULT NULL,
  `audited_at` DATETIME DEFAULT NULL,
  `effective_start_at` DATETIME DEFAULT NULL,
  `effective_end_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_expert_certification_user_region` (`user_id`,`region`),
  KEY `idx_user_expert_certification_region_status` (`region`,`status`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_follow` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `follower_user_id` BIGINT NOT NULL,
  `followed_user_id` BIGINT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_follow` (`follower_user_id`,`followed_user_id`),
  KEY `idx_user_follow_followed` (`followed_user_id`,`created_at`,`id`),
  KEY `idx_user_follow_follower` (`follower_user_id`,`created_at`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `growth_points_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `type` TINYINT NOT NULL,
  `action` VARCHAR(32) NOT NULL,
  `biz_id` BIGINT NOT NULL DEFAULT 0,
  `change_amount` INT NOT NULL,
  `balance_after` INT NOT NULL,
  `remark` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_growth_points_log_user_type_action_biz` (`user_id`, `type`, `action`, `biz_id`),
  KEY `idx_growth_points_log_user_created` (`user_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `search_history` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `keyword` VARCHAR(128) NOT NULL,
  `search_type` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_search_history_user_region_keyword` (`user_id`, `region`, `keyword`),
  KEY `idx_search_history_user_updated` (`user_id`, `updated_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `verification_code` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `scene` VARCHAR(32) NOT NULL,
  `target_type` TINYINT NOT NULL,
  `target` VARCHAR(128) NOT NULL,
  `code_hash` VARCHAR(100) NOT NULL,
  `device_id` VARCHAR(64) NOT NULL DEFAULT '',
  `request_ip` VARCHAR(45) NOT NULL DEFAULT '',
  `status` TINYINT NOT NULL DEFAULT 0,
  `expire_at` DATETIME NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_verification_lookup` (`scene`, `target_type`, `target`, `code_hash`, `status`, `id`),
  KEY `idx_verification_expire_at` (`expire_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_session` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `refresh_token_hash` VARCHAR(100) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `refresh_expire_at` DATETIME NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_session_refresh_token_hash` (`refresh_token_hash`),
  KEY `idx_user_session_user_status` (`user_id`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `import_batch` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `admin_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `file_name` VARCHAR(255) NOT NULL DEFAULT '',
  `total` INT NOT NULL DEFAULT 0,
  `success` INT NOT NULL DEFAULT 0,
  `failed` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 0,
  `error_file` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_import_batch_region_status_id` (`region`, `status`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rank_config` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rank_type` TINYINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `city_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `category_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `version` INT UNSIGNED NOT NULL DEFAULT 1,
  `calc_cycle` TINYINT NOT NULL DEFAULT 4,
  `weight_json` JSON NOT NULL,
  `min_review_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `min_score` DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  `manual_intervene` TINYINT NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 0,
  `effective_from` DATETIME DEFAULT NULL,
  `effective_to` DATETIME DEFAULT NULL,
  `updated_by` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rank_config_scope_version` (`rank_type`,`region`,`city_id`,`category_id`,`version`),
  KEY `idx_rank_config_scope_status` (`rank_type`,`region`,`city_id`,`category_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_favorite` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `target_type` TINYINT NOT NULL,
  `target_id` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_favorite_target` (`user_id`,`target_type`,`target_id`),
  KEY `idx_user_favorite_target` (`target_type`,`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `growth_rule` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `action` VARCHAR(32) NOT NULL,
  `action_name` VARCHAR(64) NOT NULL,
  `growth_value` INT NOT NULL DEFAULT 0,
  `points` INT NOT NULL DEFAULT 0,
  `daily_limit` INT NOT NULL DEFAULT 0,
  `enabled` TINYINT NOT NULL DEFAULT 1,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), UNIQUE KEY `uk_growth_rule_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `level_config` (
  `level` TINYINT NOT NULL,
  `min_growth` INT UNSIGNED NOT NULL,
  `level_name` VARCHAR(32) NOT NULL,
  `icon` VARCHAR(255) NOT NULL DEFAULT '',
  `privilege_json` JSON NOT NULL,
  `enabled` TINYINT NOT NULL DEFAULT 1,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`level`), UNIQUE KEY `uk_level_config_min_growth` (`min_growth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rank` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `type` TINYINT NOT NULL,
  `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  `city_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `category_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `config_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `period` VARCHAR(16) NOT NULL DEFAULT '',
  `enabled` TINYINT NOT NULL DEFAULT 1,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rank_region_city` (`region`,`city_id`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rank_item` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rank_id` BIGINT UNSIGNED NOT NULL,
  `shop_id` BIGINT UNSIGNED NOT NULL,
  `position` INT NOT NULL DEFAULT 0,
  `score` DECIMAL(10,2) NOT NULL DEFAULT 0,
  `reason` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `idx_rank_item_rank` (`rank_id`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `deal` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`shop_id` BIGINT UNSIGNED NOT NULL,`merchant_id` BIGINT UNSIGNED NOT NULL,`region` VARCHAR(8) NOT NULL,`type` TINYINT NOT NULL DEFAULT 1,`title` VARCHAR(128) NOT NULL,`cover_image` VARCHAR(255) NOT NULL DEFAULT '',`price` DECIMAL(10,2) NOT NULL,`original_price` DECIMAL(10,2) NOT NULL,`currency` CHAR(3) NOT NULL,`stock` INT NOT NULL DEFAULT 0,`sold_count` INT UNSIGNED NOT NULL DEFAULT 0,`valid_start` DATE DEFAULT NULL,`valid_end` DATE DEFAULT NULL,`rules` TEXT,`audit_status` TINYINT NOT NULL DEFAULT 1,`status` TINYINT NOT NULL DEFAULT 1,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,`is_deleted` TINYINT NOT NULL DEFAULT 0,PRIMARY KEY(`id`),KEY `idx_deal_shop`(`shop_id`,`status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `deal_item` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`deal_id` BIGINT UNSIGNED NOT NULL,`name` VARCHAR(128) NOT NULL,`quantity` INT NOT NULL DEFAULT 1,`price` DECIMAL(10,2) NOT NULL DEFAULT 0,`sort` INT NOT NULL DEFAULT 0,PRIMARY KEY(`id`),KEY `idx_deal_item_deal`(`deal_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `order` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`order_no` VARCHAR(32) NOT NULL,`user_id` BIGINT UNSIGNED NOT NULL,`deal_id` BIGINT UNSIGNED NOT NULL,`shop_id` BIGINT UNSIGNED NOT NULL,`region` VARCHAR(8) NOT NULL,`quantity` INT NOT NULL,`unit_price` DECIMAL(10,2) NOT NULL,`amount` DECIMAL(10,2) NOT NULL,`currency` CHAR(3) NOT NULL,`pay_method` VARCHAR(16) NOT NULL DEFAULT '',`pay_status` TINYINT NOT NULL DEFAULT 0,`status` TINYINT NOT NULL DEFAULT 1,`paid_at` DATETIME DEFAULT NULL,`expire_at` DATETIME DEFAULT NULL,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY(`id`),UNIQUE KEY `uk_order_no`(`order_no`),KEY `idx_order_user`(`user_id`,`pay_status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `payment` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`order_id` BIGINT UNSIGNED NOT NULL,`order_no` VARCHAR(32) NOT NULL,`channel` VARCHAR(16) NOT NULL,`channel_txn` VARCHAR(64) NOT NULL DEFAULT '',`amount` DECIMAL(10,2) NOT NULL,`currency` CHAR(3) NOT NULL,`status` TINYINT NOT NULL DEFAULT 0,`raw_response` TEXT,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY(`id`),UNIQUE KEY `uk_payment_channel_txn`(`channel`,`channel_txn`),KEY `idx_payment_order`(`order_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `coupon` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`order_id` BIGINT UNSIGNED NOT NULL,`user_id` BIGINT UNSIGNED NOT NULL,`deal_id` BIGINT UNSIGNED NOT NULL,`shop_id` BIGINT UNSIGNED NOT NULL,`code` VARCHAR(32) NOT NULL,`status` TINYINT NOT NULL DEFAULT 1,`verify_at` DATETIME DEFAULT NULL,`verify_by` BIGINT UNSIGNED NOT NULL DEFAULT 0,`expire_at` DATE DEFAULT NULL,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(`id`),UNIQUE KEY `uk_coupon_code`(`code`),KEY `idx_coupon_user_status`(`user_id`,`status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `refund` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`order_id` BIGINT UNSIGNED NOT NULL,`coupon_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,`amount` DECIMAL(10,2) NOT NULL,`reason` VARCHAR(255) NOT NULL DEFAULT '',`status` TINYINT NOT NULL DEFAULT 0,`audit_by` BIGINT UNSIGNED NOT NULL DEFAULT 0,`audit_reason` VARCHAR(255) NOT NULL DEFAULT '',`audited_at` DATETIME DEFAULT NULL,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY(`id`),UNIQUE KEY `uk_refund_order`(`order_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `reservation_slot` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`shop_id` BIGINT UNSIGNED NOT NULL,`region` VARCHAR(8) NOT NULL,`biz_date` DATE NOT NULL,`start_time` TIME NOT NULL,`end_time` TIME NOT NULL,`capacity` INT NOT NULL,`reserved_count` INT NOT NULL DEFAULT 0,`confirm_mode` TINYINT NOT NULL DEFAULT 2,`cancel_before_minutes` INT NOT NULL DEFAULT 120,`enabled` TINYINT NOT NULL DEFAULT 1,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY(`id`),KEY `idx_reservation_slot_shop_date`(`shop_id`,`biz_date`,`enabled`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `reservation` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`reservation_no` VARCHAR(32) NOT NULL,`user_id` BIGINT UNSIGNED NOT NULL,`shop_id` BIGINT UNSIGNED NOT NULL,`slot_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,`region` VARCHAR(8) NOT NULL,`reserve_time` DATETIME NOT NULL,`people_count` INT NOT NULL,`contact_name` VARCHAR(64) NOT NULL,`contact_phone` VARCHAR(32) NOT NULL,`remark` VARCHAR(255) NOT NULL DEFAULT '',`status` TINYINT NOT NULL DEFAULT 0,`merchant_staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,`confirmed_at` DATETIME DEFAULT NULL,`arrived_at` DATETIME DEFAULT NULL,`cancelled_at` DATETIME DEFAULT NULL,`rejected_at` DATETIME DEFAULT NULL,`reschedule_count` TINYINT NOT NULL DEFAULT 0,`remind_status` TINYINT NOT NULL DEFAULT 0,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,`updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY(`id`),UNIQUE KEY `uk_reservation_no`(`reservation_no`),KEY `idx_reservation_user_status`(`user_id`,`status`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `reservation_change_log` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`reservation_id` BIGINT UNSIGNED NOT NULL,`action_type` TINYINT NOT NULL,`operator_type` TINYINT NOT NULL,`operator_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,`from_status` TINYINT NOT NULL DEFAULT 0,`to_status` TINYINT NOT NULL DEFAULT 0,`old_reserve_time` DATETIME DEFAULT NULL,`new_reserve_time` DATETIME DEFAULT NULL,`remark` VARCHAR(255) NOT NULL DEFAULT '',`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(`id`),KEY `idx_reservation_change`(`reservation_id`,`created_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE `user_notification` (`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,`user_id` BIGINT UNSIGNED NOT NULL,`actor_user_id` BIGINT UNSIGNED DEFAULT NULL,`region` VARCHAR(8) NOT NULL,`type` VARCHAR(64) NOT NULL,`title` VARCHAR(128) NOT NULL,`content` VARCHAR(500) NOT NULL DEFAULT '',`link_url` VARCHAR(255) NOT NULL DEFAULT '',`aggregate_count` INT NOT NULL DEFAULT 1,`is_read` TINYINT NOT NULL DEFAULT 0,`read_at` DATETIME DEFAULT NULL,`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(`id`),KEY `idx_user_notification_user_region_read`(`user_id`,`region`,`is_read`,`id`),KEY `idx_user_notification_actor`(`actor_user_id`,`type`,`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE IF NOT EXISTS conversation (id BIGINT AUTO_INCREMENT PRIMARY KEY,user_a BIGINT NOT NULL,user_b BIGINT NOT NULL,last_message_id BIGINT NULL,last_message_preview VARCHAR(200) NOT NULL DEFAULT '',last_message_at TIMESTAMP NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,UNIQUE KEY uk_conversation_users(user_a,user_b),KEY idx_conversation_user_a(user_a,last_message_at,id),KEY idx_conversation_user_b(user_b,last_message_at,id));
CREATE TABLE IF NOT EXISTS message (id BIGINT AUTO_INCREMENT PRIMARY KEY,conversation_id BIGINT NOT NULL,from_user_id BIGINT NOT NULL,to_user_id BIGINT NOT NULL,content VARCHAR(2000) NOT NULL,is_read TINYINT(1) NOT NULL DEFAULT 0,read_at TIMESTAMP NULL,status TINYINT NOT NULL DEFAULT 1,is_deleted TINYINT(1) NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,KEY idx_message_conversation(conversation_id,id),KEY idx_message_unread(to_user_id,is_read,id));
CREATE TABLE IF NOT EXISTS user_block (id BIGINT AUTO_INCREMENT PRIMARY KEY,user_id BIGINT NOT NULL,blocked_user_id BIGINT NOT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uk_user_block(user_id,blocked_user_id),KEY idx_user_block_blocked(blocked_user_id,user_id));
CREATE TABLE IF NOT EXISTS message_report (id BIGINT AUTO_INCREMENT PRIMARY KEY,reporter_user_id BIGINT NOT NULL,target_type TINYINT NOT NULL,target_id BIGINT NOT NULL,reason VARCHAR(255) NOT NULL,status TINYINT NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uk_message_report(reporter_user_id,target_type,target_id),KEY idx_message_report_status(status,id));
CREATE TABLE IF NOT EXISTS circle (id BIGINT AUTO_INCREMENT PRIMARY KEY,region VARCHAR(8) NOT NULL,name VARCHAR(64) NOT NULL,description VARCHAR(500) NOT NULL DEFAULT '',cover_url VARCHAR(255) NOT NULL DEFAULT '',member_count INT NOT NULL DEFAULT 0,post_count INT NOT NULL DEFAULT 0,sort INT NOT NULL DEFAULT 0,status TINYINT NOT NULL DEFAULT 1,created_by BIGINT NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,is_deleted TINYINT(1) NOT NULL DEFAULT 0,UNIQUE KEY uk_circle_region_name(region,name),KEY idx_circle_region_status_sort(region,status,is_deleted,sort,id));
CREATE TABLE IF NOT EXISTS circle_member (id BIGINT AUTO_INCREMENT PRIMARY KEY,circle_id BIGINT NOT NULL,user_id BIGINT NOT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE KEY uk_circle_member(circle_id,user_id),KEY idx_circle_member_user(user_id,circle_id));
ALTER TABLE post ADD COLUMN circle_id BIGINT NULL, ADD KEY idx_post_circle_status(circle_id,audit_status,status,is_deleted,id);
