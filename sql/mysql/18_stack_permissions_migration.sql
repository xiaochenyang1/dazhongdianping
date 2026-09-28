-- 补齐 stack 特性(投诉纠纷 / 付费推广 / 在线咨询 / 排队候位 / 风控)在生产库缺失的权限种子。
-- 17 号补建了特性表并加入 risk:event 权限行，但遗漏了：
--   1) 后台 audit:complaint:* 与 operations:ad:* 两组权限从未进任何迁移；
--   2) risk:event:* 只写入 admin_permission，未挂到任何 admin 角色（连 super_admin 都访问不到风控看板）；
--   3) 商户角色 merchant_role 缺 complaint/ad/consult/waitlist 权限串。
-- 挂接关系与 backend data.sql 对齐：super_admin 全量、merchant_auditor 拿 risk:event+audit:complaint、operations_manager 拿 operations:ad。
-- 不回写 01_schema.sql / 02_seed_data.sql。全部 ON DUPLICATE KEY / INSERT IGNORE / NOT LIKE 守卫，可安全重跑。

-- ============ 后台权限行（投诉纠纷、付费推广审核） ============
INSERT INTO `admin_permission` (`code`, `name`, `category`, `permission_type`, `status`) VALUES
  ('audit:complaint:read', '查看投诉纠纷工单', 'audit', 1, 1),
  ('audit:complaint:write', '仲裁处置投诉纠纷', 'audit', 2, 1),
  ('operations:ad:read', '查看广告投放', 'operations', 1, 1),
  ('operations:ad:write', '审核处置广告投放', 'operations', 2, 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `category` = VALUES(`category`),
  `permission_type` = VALUES(`permission_type`),
  `status` = VALUES(`status`);

-- ============ 角色挂接 ============
-- super_admin：本轮全部新权限 + 补挂 17 号遗漏的 risk:event:*
INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'audit:complaint:read', 'audit:complaint:write',
  'operations:ad:read', 'operations:ad:write',
  'risk:event:read', 'risk:event:write'
)
WHERE r.`code` = 'super_admin';

-- merchant_auditor（商户审核员）：风控事件 + 投诉纠纷仲裁
INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN (
  'risk:event:read', 'risk:event:write',
  'audit:complaint:read', 'audit:complaint:write'
)
WHERE r.`code` = 'merchant_auditor';

-- operations_manager（运营管理员）：广告投放
INSERT IGNORE INTO `admin_role_permission` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id`
FROM `admin_role` r
INNER JOIN `admin_permission` p ON p.`code` IN ('operations:ad:read', 'operations:ad:write')
WHERE r.`code` = 'operations_manager';

-- ============ 商户角色权限串 ============
-- 主账号 / 店长：投诉、广告、咨询、排队全套
UPDATE `merchant_role`
SET `permissions` = CONCAT(`permissions`, ',complaint:view,complaint:reply,ad:view,ad:manage,consult:view,consult:reply,waitlist:view,waitlist:manage')
WHERE `code` IN ('owner', 'store_manager')
  AND `permissions` NOT LIKE '%complaint:view%';

-- 核销员：仅叫号 / 候位
UPDATE `merchant_role`
SET `permissions` = CONCAT(`permissions`, ',waitlist:view,waitlist:manage')
WHERE `code` = 'coupon_operator'
  AND `permissions` NOT LIKE '%waitlist:view%';

-- 客服运营：投诉、咨询、排队（无广告）
UPDATE `merchant_role`
SET `permissions` = CONCAT(`permissions`, ',complaint:view,complaint:reply,consult:view,consult:reply,waitlist:view,waitlist:manage')
WHERE `code` = 'service_operator'
  AND `permissions` NOT LIKE '%complaint:view%';
