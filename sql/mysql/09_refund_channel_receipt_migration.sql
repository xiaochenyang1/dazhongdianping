ALTER TABLE `refund`
    ADD COLUMN `channel` VARCHAR(32) NOT NULL DEFAULT '' AFTER `audit_reason`,
    ADD COLUMN `channel_refund_txn` VARCHAR(128) NOT NULL DEFAULT '' AFTER `channel`,
    ADD KEY `idx_refund_channel_txn` (`channel`, `channel_refund_txn`);
