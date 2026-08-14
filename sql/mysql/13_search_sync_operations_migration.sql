-- 搜索同步任务后台监控权限。
-- 适用于已执行过基础 seed 的既有数据库；新数据库直接导入 01_schema.sql + 02_seed_data.sql。

INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`)
VALUES ('data:search_index:read', '查看搜索同步任务', 'data', 1, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` = 'data:search_index:read'
WHERE r.`code` IN ('super_admin', 'data_operator');
