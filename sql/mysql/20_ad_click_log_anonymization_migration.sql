-- 广告点击账单明细只需 campaign/shop/region/cost/time 做核对；用户身份不参与商户报表或计费。
-- 清除既有明细中的账号关联，后续写入省略 user_id 并使用列默认值 0。
UPDATE `ad_click_log`
SET `user_id` = 0
WHERE `user_id` <> 0;
