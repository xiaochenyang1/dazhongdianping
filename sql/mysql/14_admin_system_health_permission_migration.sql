-- 管理端系统健康监控权限。
-- 健康信息跨区域且包含基础设施状态，默认仅授予超级管理员。

INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`)
VALUES ('system:health:read', '查看系统健康状态', 'system', 1, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);

INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` = 'system:health:read'
WHERE r.`code` = 'super_admin';
