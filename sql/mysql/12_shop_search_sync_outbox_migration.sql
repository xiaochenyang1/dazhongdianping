-- MySQL -> Elasticsearch 门店索引可靠同步任务。
-- 任务按 shop_id 合并；version 用于防止投递过程中的新变更被旧任务错误清除。
CREATE TABLE `shop_search_sync_task` (
  `shop_id` BIGINT NOT NULL,
  `version` BIGINT UNSIGNED NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0=待投递,1=投递中',
  `attempt_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `next_retry_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `locked_at` DATETIME DEFAULT NULL,
  `last_error` VARCHAR(1000) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`shop_id`),
  KEY `idx_shop_search_sync_dispatch` (`status`,`next_retry_at`,`locked_at`,`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
