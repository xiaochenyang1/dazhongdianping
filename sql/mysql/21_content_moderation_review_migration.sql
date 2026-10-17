-- Add visibility states for shop Q&A moderation. Existing rows remain public.
ALTER TABLE `shop_question`
  ADD COLUMN `status` TINYINT NOT NULL DEFAULT 1 AFTER `answer_count`;

ALTER TABLE `shop_answer`
  ADD COLUMN `status` TINYINT NOT NULL DEFAULT 1 AFTER `content`;

CREATE INDEX `idx_shop_question_visibility`
  ON `shop_question` (`shop_id`, `region`, `status`, `is_deleted`, `id`);

CREATE INDEX `idx_shop_answer_visibility`
  ON `shop_answer` (`question_id`, `status`, `is_deleted`, `id`);
