-- 补齐营销券后台(operations:marketing:*)与推荐权重后台(operations:recommendation:*)的权限种子。
-- 这两组权限码被 AdminMarketingController / AdminMarketingCampaignController /
-- AdminRecommendationController 及后台菜单引用,在 backend data.sql 已定义并挂 super_admin/
-- operations_manager,但 16 号营销迁移只建券表、未写 admin_permission,17/18 也未补 ->
-- 生产 admin_permission 缺这 4 行,含 super_admin 在内所有管理员访问券模板/活动审核/推荐权重
-- 后台端点全部 403,商户券/秒杀/拼团永远停在待审无人能放行。
-- 挂接关系与 backend data.sql 对齐(super_admin 全量、operations_manager 两组都拿)。
-- 全部 ON DUPLICATE KEY / INSERT IGNORE 守卫,可安全重跑。放在 18 号之后。

INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`) VALUES
  ('operations:recommendation:read', '查看推荐权重配置', 'operations', 1, 1),
  ('operations:recommendation:write', '维护推荐权重配置', 'operations', 2, 1),
  ('operations:marketing:read', '查看营销券模板', 'operations', 1, 1),
  ('operations:marketing:write', '维护营销券模板', 'operations', 2, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);

-- super_admin:全量
INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'operations:recommendation:read', 'operations:recommendation:write',
  'operations:marketing:read', 'operations:marketing:write'
)
WHERE r.`code` = 'super_admin';

-- operations_manager(运营管理员):营销券 + 推荐权重
INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'operations:recommendation:read', 'operations:recommendation:write',
  'operations:marketing:read', 'operations:marketing:write'
)
WHERE r.`code` = 'operations_manager';
