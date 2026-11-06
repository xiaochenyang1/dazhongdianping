-- Manual creator review; status 2 legacy awards remain terminal and are never re-issued.
ALTER TABLE creator_task_claim
    ADD COLUMN task_title VARCHAR(128),
    ADD COLUMN task_description VARCHAR(1000),
    ADD COLUMN reward_points INT,
    ADD COLUMN evidence_type VARCHAR(8),
    ADD COLUMN evidence_id BIGINT,
    ADD COLUMN submission_note VARCHAR(1000) NOT NULL DEFAULT '',
    ADD COLUMN submission_version INT NOT NULL DEFAULT 0,
    ADD COLUMN submitted_at DATETIME NULL,
    ADD COLUMN review_note VARCHAR(1000) NOT NULL DEFAULT '',
    ADD COLUMN reviewed_by BIGINT,
    ADD COLUMN reviewed_at DATETIME NULL,
    ADD INDEX idx_creator_claim_review(region, status, id);

-- Freeze terms for existing claims. Historical awards use their recorded ledger amount.
UPDATE creator_task_claim c
LEFT JOIN creator_task t ON t.id=c.task_id AND t.region=c.region
LEFT JOIN (SELECT biz_id, MAX(change_amount) AS awarded FROM growth_points_log
           WHERE action='creator_task' AND type=2 GROUP BY biz_id) g ON g.biz_id=c.id
SET c.task_title=COALESCE(t.title, ''), c.task_description=COALESCE(t.description, ''),
    c.reward_points=CASE WHEN c.status=2 THEN COALESCE(g.awarded,t.reward_points,0)
                        ELSE COALESCE(t.reward_points,0) END;
