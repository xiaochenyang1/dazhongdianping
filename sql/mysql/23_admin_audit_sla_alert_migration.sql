CREATE TABLE `admin_audit_sla_alert` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(8) NOT NULL,
  `biz_type` TINYINT NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0=active, 1=resolved',
  `active_key` VARCHAR(16) DEFAULT NULL,
  `pending_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `overdue_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `oldest_pending_at` DATETIME DEFAULT NULL,
  `first_overdue_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_detected_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_audit_sla_alert_active_key` (`active_key`),
  KEY `idx_admin_audit_sla_alert_region_status` (`region`, `status`, `first_overdue_at`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
