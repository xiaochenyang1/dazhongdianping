-- Real flash-sale orders. Existing participation records remain historical;
-- they must never be mistaken for paid orders or trigger coupon issuance.
ALTER TABLE `order`
    ADD COLUMN order_source VARCHAR(16) NOT NULL DEFAULT 'deal',
    ADD COLUMN campaign_id BIGINT UNSIGNED NULL,
    ADD COLUMN campaign_title VARCHAR(128) NOT NULL DEFAULT '',
    ADD COLUMN deal_title_snapshot VARCHAR(128) NOT NULL DEFAULT '',
    ADD COLUMN coupon_valid_end DATE NULL,
    ADD COLUMN inventory_released BOOLEAN NOT NULL DEFAULT FALSE,
    ADD INDEX idx_order_campaign(order_source, campaign_id, inventory_released),
    ADD INDEX idx_order_expiry(status, pay_status, expire_at, id);

-- These orders already returned their stock under the previous lifecycle.
UPDATE `order` SET inventory_released=TRUE WHERE status=2 OR pay_status=2;

ALTER TABLE seckill_claim
    ADD COLUMN order_id BIGINT UNSIGNED NULL,
    ADD COLUMN status TINYINT NOT NULL DEFAULT 0 COMMENT '0 legacy,1 reserved,2 paid,3 released,4 refunded',
    ADD COLUMN updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ADD UNIQUE KEY uk_seckill_claim_order(order_id),
    ADD INDEX idx_seckill_claim_user(region, user_id, status);

ALTER TABLE refund
    ADD COLUMN refund_type VARCHAR(24) NOT NULL DEFAULT 'user',
    ADD INDEX idx_refund_auto(refund_type, status, updated_at, id);
