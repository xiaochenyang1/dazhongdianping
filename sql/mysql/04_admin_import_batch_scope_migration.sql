-- Non-destructive migration for scoped admin import-batch queries.
-- Run once after 03_admin_city_scope_migration.sql on existing databases.

CREATE INDEX `idx_import_batch_region_admin_status_id`
  ON `import_batch` (`region`, `admin_id`, `status`, `id`);
