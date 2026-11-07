-- 拼团交易闭环：成员订单、付款人数、到期自动退款与库存补偿。

ALTER TABLE `groupbuy_team`
  ADD COLUMN `paid_count` INT NOT NULL DEFAULT 0 AFTER `member_count`,
  ADD KEY `idx_groupbuy_team_expire` (`status`, `expire_at`, `id`);

ALTER TABLE `groupbuy_member`
  ADD COLUMN `campaign_id` BIGINT NULL AFTER `team_id`,
  ADD COLUMN `region` VARCHAR(8) NULL AFTER `campaign_id`,
  ADD COLUMN `order_id` BIGINT UNSIGNED NULL AFTER `user_id`,
  ADD COLUMN `status` TINYINT NOT NULL DEFAULT 2 AFTER `order_id`,
  ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;

UPDATE `groupbuy_member` m
JOIN `groupbuy_team` t ON t.id=m.team_id
SET m.campaign_id=t.campaign_id,m.region=t.region
WHERE m.campaign_id IS NULL OR m.region IS NULL;

ALTER TABLE `groupbuy_member`
  MODIFY COLUMN `campaign_id` BIGINT NOT NULL,
  MODIFY COLUMN `region` VARCHAR(8) NOT NULL DEFAULT 'CN',
  ADD UNIQUE KEY `uk_groupbuy_member_order` (`order_id`),
  ADD KEY `idx_groupbuy_member_campaign_user` (`campaign_id`, `user_id`, `region`, `status`, `id`);

-- 历史成员没有订单，只保留为历史参与记录，不参与新的成团计数。
UPDATE `groupbuy_team` t
SET t.paid_count=(
  SELECT COUNT(*) FROM `groupbuy_member` m WHERE m.team_id=t.id AND m.status=1
),t.updated_at=CURRENT_TIMESTAMP;
