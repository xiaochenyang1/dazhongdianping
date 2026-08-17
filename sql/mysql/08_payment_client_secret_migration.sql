-- Non-destructive migration for payment form recovery after a page refresh.
-- Run once after 07_points_mall_migration.sql on existing databases.
-- Fresh installs already include this column in 01_schema.sql.

ALTER TABLE `payment`
  ADD COLUMN `client_secret` VARCHAR(255) NOT NULL DEFAULT '' AFTER `channel_txn`;
