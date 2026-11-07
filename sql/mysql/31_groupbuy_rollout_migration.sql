-- 拼团灰度：总熔断 + 活动/门店/城市规则 + 稳定用户比例。

ALTER TABLE `groupbuy_member`
  ADD COLUMN `remind_status` TINYINT NOT NULL DEFAULT 0 AFTER `status`;

CREATE TABLE IF NOT EXISTS `feature_flag_scope` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `feature_flag_id` BIGINT NOT NULL,
  `scope_type` VARCHAR(16) NOT NULL,
  `scope_id` BIGINT NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `rollout_percent` INT NOT NULL DEFAULT 100,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_feature_flag_scope` (`feature_flag_id`,`scope_type`,`scope_id`),
  KEY `idx_feature_flag_scope_lookup` (`feature_flag_id`,`scope_type`,`scope_id`),
  CONSTRAINT `fk_feature_flag_scope_flag` FOREIGN KEY (`feature_flag_id`) REFERENCES `feature_flag` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `feature_flag` (`region`,`flag_key`,`description`,`enabled`,`rollout_percent`)
SELECT 'CN','group_buy','拼团总熔断与灰度开关',0,0
WHERE NOT EXISTS(SELECT 1 FROM `feature_flag` WHERE `region`='CN' AND `flag_key`='group_buy');

INSERT INTO `feature_flag` (`region`,`flag_key`,`description`,`enabled`,`rollout_percent`)
SELECT 'EU','group_buy','Group-buy kill switch and rollout',0,0
WHERE NOT EXISTS(SELECT 1 FROM `feature_flag` WHERE `region`='EU' AND `flag_key`='group_buy');
