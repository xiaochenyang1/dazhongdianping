-- Non-destructive migration for existing databases.
-- Existing region grants retain their previous behavior by defaulting to all cities.

ALTER TABLE `admin_region_scope`
  ADD COLUMN `all_cities` TINYINT(1) NOT NULL DEFAULT 1 AFTER `region`;

CREATE TABLE IF NOT EXISTS `admin_city_scope` (
  `admin_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `city_id` BIGINT NOT NULL,
  PRIMARY KEY (`admin_id`, `region`, `city_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_shop_scope` (
  `admin_id` BIGINT NOT NULL,
  `region` VARCHAR(8) NOT NULL,
  `shop_id` BIGINT NOT NULL,
  PRIMARY KEY (`admin_id`, `region`, `shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
