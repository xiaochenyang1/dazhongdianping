CREATE TABLE IF NOT EXISTS category (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    parent_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    name VARCHAR_IGNORECASE(64) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_category_region_parent_name
    ON category(region, parent_id, name);
CREATE INDEX IF NOT EXISTS idx_category_region_status_parent_sort
    ON category(region, status, parent_id, sort_no, id);

CREATE TABLE IF NOT EXISTS city (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL,
    region VARCHAR(8) NOT NULL,
    name VARCHAR_IGNORECASE(64) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_city_region_code ON city(region, code);
CREATE UNIQUE INDEX IF NOT EXISTS uk_city_region_name ON city(region, name);
CREATE INDEX IF NOT EXISTS idx_city_region_status_sort
    ON city(region, status, sort_no, id);

CREATE TABLE IF NOT EXISTS area (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    city_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    name VARCHAR_IGNORECASE(64) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_area_region_city_name
    ON area(region, city_id, name);
CREATE INDEX IF NOT EXISTS idx_area_region_city_status_sort
    ON area(region, city_id, status, sort_no, id);

CREATE TABLE IF NOT EXISTS admin_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    account VARCHAR(64) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    name VARCHAR(64) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_admin_user_account ON admin_user(account);

CREATE TABLE IF NOT EXISTS admin_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(255) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    built_in BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_admin_role_code ON admin_role(code);

CREATE TABLE IF NOT EXISTS admin_permission (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(96) NOT NULL,
    name VARCHAR(64) NOT NULL,
    category VARCHAR(32) NOT NULL,
    permission_type TINYINT NOT NULL DEFAULT 3,
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_admin_permission_code ON admin_permission(code);

CREATE TABLE IF NOT EXISTS admin_user_role (
    admin_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (admin_id, role_id)
);

CREATE TABLE IF NOT EXISTS admin_role_permission (
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS admin_region_scope (
    admin_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    PRIMARY KEY (admin_id, region)
);

CREATE INDEX IF NOT EXISTS idx_admin_user_status ON admin_user(status, id);
CREATE INDEX IF NOT EXISTS idx_admin_role_status ON admin_role(status, id);
CREATE INDEX IF NOT EXISTS idx_admin_user_role_role ON admin_user_role(role_id, admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_role_permission_permission ON admin_role_permission(permission_id, role_id);

CREATE TABLE IF NOT EXISTS merchant (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    account VARCHAR(128) NOT NULL,
    company_name VARCHAR(128) NOT NULL,
    contact_name VARCHAR(64) NOT NULL DEFAULT '',
    contact_phone VARCHAR(32) NOT NULL DEFAULT '',
    region VARCHAR(8) NOT NULL,
    audit_status TINYINT NOT NULL DEFAULT 1,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_merchant_account ON merchant(account);

CREATE TABLE IF NOT EXISTS merchant_operator (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    account VARCHAR(128) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    name VARCHAR(64) NOT NULL,
    phone VARCHAR(32) NOT NULL DEFAULT '',
    email VARCHAR(128) NOT NULL DEFAULT '',
    operator_type TINYINT NOT NULL DEFAULT 2,
    shop_scope_type TINYINT NOT NULL DEFAULT 2,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_merchant_operator_account ON merchant_operator(account);
CREATE INDEX IF NOT EXISTS idx_merchant_operator_merchant_status
    ON merchant_operator(merchant_id, status, is_deleted, id);

CREATE TABLE IF NOT EXISTS merchant_role (
    id BIGINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(64) NOT NULL,
    permissions VARCHAR(1000) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_merchant_role_code ON merchant_role(code);

CREATE TABLE IF NOT EXISTS merchant_operator_role (
    operator_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_merchant_operator_role UNIQUE(operator_id, role_id)
);

CREATE TABLE IF NOT EXISTS merchant_operator_shop (
    operator_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_merchant_operator_shop UNIQUE(operator_id, shop_id)
);

CREATE TABLE IF NOT EXISTS merchant_application (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    license_url VARCHAR(255) NOT NULL DEFAULT '',
    legal_person VARCHAR(64) NOT NULL DEFAULT '',
    shop_photo_urls VARCHAR(2000) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_merchant_application_merchant ON merchant_application(merchant_id);
CREATE INDEX IF NOT EXISTS idx_merchant_application_status ON merchant_application(status, updated_at, id);

CREATE TABLE IF NOT EXISTS merchant_operation_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    action VARCHAR(64) NOT NULL,
    target_type VARCHAR(32) NOT NULL DEFAULT '',
    target_id BIGINT NOT NULL DEFAULT 0,
    detail VARCHAR(1000) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_merchant_operation_log_merchant
    ON merchant_operation_log(merchant_id, created_at, id);

CREATE TABLE IF NOT EXISTS merchant_shop_change (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    change_type TINYINT NOT NULL,
    target_shop_id BIGINT NOT NULL DEFAULT 0,
    base_updated_at TIMESTAMP NULL,
    category_id BIGINT NOT NULL DEFAULT 0,
    city_id BIGINT NOT NULL DEFAULT 0,
    area_id BIGINT NOT NULL DEFAULT 0,
    name VARCHAR(128) NOT NULL DEFAULT '',
    cover_url VARCHAR(255) NOT NULL DEFAULT '',
    phone VARCHAR(64) NOT NULL DEFAULT '',
    price_per_capita DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'CNY',
    address VARCHAR(255) NOT NULL DEFAULT '',
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    business_hours VARCHAR(128) NOT NULL DEFAULT '',
    summary VARCHAR(255) NOT NULL DEFAULT '',
    open_now BOOLEAN NOT NULL DEFAULT TRUE,
    tags VARCHAR(255) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shop_change_merchant_status
    ON merchant_shop_change(merchant_id, region, status, id);
CREATE INDEX IF NOT EXISTS idx_shop_change_target_status
    ON merchant_shop_change(target_shop_id, status, id);

CREATE TABLE IF NOT EXISTS merchant_shop_change_photo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    change_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    photo_type TINYINT NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_shop_change_photo
    ON merchant_shop_change_photo(change_id, sort_no, id);

CREATE TABLE IF NOT EXISTS merchant_shop_change_dish (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    change_id BIGINT NOT NULL,
    name VARCHAR(64) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    recommend_reason VARCHAR(255) NOT NULL DEFAULT '',
    sort_no INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_shop_change_dish
    ON merchant_shop_change_dish(change_id, sort_no, id);

CREATE TABLE IF NOT EXISTS shop (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL DEFAULT 0,
    category_id BIGINT NOT NULL,
    city_id BIGINT NOT NULL,
    area_id BIGINT NOT NULL,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    region VARCHAR(8) NOT NULL,
    name VARCHAR(128) NOT NULL,
    cover_url VARCHAR(255) NOT NULL,
    phone VARCHAR(64) NOT NULL DEFAULT '',
    score DECIMAL(3,1) NOT NULL,
    taste_score DECIMAL(3,1) NOT NULL,
    env_score DECIMAL(3,1) NOT NULL,
    service_score DECIMAL(3,1) NOT NULL,
    review_count INT NOT NULL DEFAULT 0,
    price_per_capita DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'CNY',
    address VARCHAR(255) NOT NULL,
    business_hours VARCHAR(128) NOT NULL,
    summary VARCHAR(255) NOT NULL,
    has_deal BOOLEAN NOT NULL DEFAULT FALSE,
    open_now BOOLEAN NOT NULL DEFAULT TRUE,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    tags VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_shop_region_city_category ON shop(region, city_id, category_id);
CREATE INDEX IF NOT EXISTS idx_shop_merchant_id ON shop(merchant_id);

CREATE TABLE IF NOT EXISTS shop_view_daily (
    shop_id BIGINT NOT NULL,
    biz_date DATE NOT NULL,
    view_count BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_shop_view_daily UNIQUE(shop_id, biz_date)
);

CREATE INDEX IF NOT EXISTS idx_shop_view_daily_date ON shop_view_daily(biz_date, shop_id);

CREATE TABLE IF NOT EXISTS shop_photo (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    photo_type TINYINT NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS dish (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    name VARCHAR(64) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    recommend_reason VARCHAR(255) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS home_banner (
    id BIGINT PRIMARY KEY,
    city_id BIGINT,
    region VARCHAR(8) NOT NULL,
    title VARCHAR(128) NOT NULL,
    subtitle VARCHAR(255),
    image_url VARCHAR(255) NOT NULL,
    link_url VARCHAR(255) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS hot_keyword (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(8) NOT NULL,
    keyword VARCHAR(64) NOT NULL,
    sort INT NOT NULL DEFAULT 0,
    enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS operation_activity (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    code VARCHAR(64) NOT NULL,
    region VARCHAR(8) NOT NULL DEFAULT 'CN',
    city_id BIGINT NOT NULL DEFAULT 0,
    channel TINYINT NOT NULL DEFAULT 1,
    type TINYINT NOT NULL DEFAULT 1,
    status TINYINT NOT NULL DEFAULT 0,
    cover VARCHAR(255) NOT NULL DEFAULT '',
    landing_url VARCHAR(255) NOT NULL DEFAULT '',
    rule_json VARCHAR(2000) NOT NULL DEFAULT '{}',
    start_at TIMESTAMP NULL,
    end_at TIMESTAMP NULL,
    created_by BIGINT NOT NULL DEFAULT 0,
    updated_by BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_operation_activity_code ON operation_activity(code);
CREATE INDEX IF NOT EXISTS idx_operation_activity_region_city_status
    ON operation_activity(region, city_id, status, start_at, id);

CREATE TABLE IF NOT EXISTS operation_activity_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    activity_id BIGINT NOT NULL,
    target_type TINYINT NOT NULL,
    target_id BIGINT NOT NULL DEFAULT 0,
    title VARCHAR(128) NOT NULL DEFAULT '',
    subtitle VARCHAR(255) NOT NULL DEFAULT '',
    image VARCHAR(255) NOT NULL DEFAULT '',
    sort INT NOT NULL DEFAULT 0,
    extra_json VARCHAR(2000) NOT NULL DEFAULT '{}',
    status TINYINT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_operation_activity_item_target
    ON operation_activity_item(activity_id, target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_operation_activity_item_sort
    ON operation_activity_item(activity_id, status, sort, id);

CREATE TABLE IF NOT EXISTS home_feed (
    id BIGINT PRIMARY KEY,
    city_id BIGINT,
    shop_id BIGINT,
    region VARCHAR(8) NOT NULL,
    feed_type VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    subtitle VARCHAR(255),
    cover_url VARCHAR(255) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS review (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL DEFAULT 0,
    shop_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    content VARCHAR(500) NOT NULL,
    score_overall DECIMAL(3,1) NOT NULL,
    score_taste DECIMAL(3,1) NOT NULL DEFAULT 0,
    score_env DECIMAL(3,1) NOT NULL DEFAULT 0,
    score_service DECIMAL(3,1) NOT NULL DEFAULT 0,
    cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'CNY',
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    audit_status TINYINT NOT NULL DEFAULT 0,
    audit_remark VARCHAR(255) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    tags VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_review_shop_public ON review(shop_id, audit_status, status, is_deleted, created_at);
CREATE INDEX IF NOT EXISTS idx_review_user_id ON review(user_id, is_deleted, created_at);

CREATE TABLE IF NOT EXISTS review_image (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    url VARCHAR(255) NOT NULL,
    media_type TINYINT NOT NULL DEFAULT 1,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_review_image_review_id ON review_image(review_id, sort_no);

CREATE TABLE IF NOT EXISTS review_like (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_review_like_review_user ON review_like(review_id, user_id);
CREATE INDEX IF NOT EXISTS idx_review_like_review_id ON review_like(review_id, id);

CREATE TABLE IF NOT EXISTS review_comment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    content VARCHAR(300) NOT NULL,
    parent_id BIGINT NOT NULL DEFAULT 0,
    reply_to BIGINT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_review_comment_review_id ON review_comment(review_id, status, is_deleted, parent_id, created_at, id);

CREATE TABLE IF NOT EXISTS review_report (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    reporter_user_id BIGINT NOT NULL,
    reporter_user_name VARCHAR(64) NOT NULL,
    reason VARCHAR(200) NOT NULL,
    status TINYINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_review_report_review_id ON review_report(review_id, status, is_deleted, id);
CREATE INDEX IF NOT EXISTS idx_review_report_user_id ON review_report(reporter_user_id, review_id, id);

CREATE TABLE IF NOT EXISTS review_merchant_reply (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    content VARCHAR(500) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_review_merchant_reply_review
    ON review_merchant_reply(review_id);
CREATE INDEX IF NOT EXISTS idx_review_merchant_reply_shop
    ON review_merchant_reply(shop_id, updated_at);

CREATE TABLE IF NOT EXISTS merchant_review_appeal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    merchant_id BIGINT NOT NULL,
    operator_id BIGINT NOT NULL,
    review_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    base_review_updated_at TIMESTAMP NULL,
    reason VARCHAR(500) NOT NULL DEFAULT '',
    evidence_urls VARCHAR(2000) NOT NULL DEFAULT '[]',
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_merchant_review_appeal
    ON merchant_review_appeal(merchant_id, review_id);
CREATE INDEX IF NOT EXISTS idx_merchant_review_appeal_status
    ON merchant_review_appeal(merchant_id, region, status, id);
CREATE INDEX IF NOT EXISTS idx_merchant_review_appeal_shop
    ON merchant_review_appeal(shop_id, status, id);

CREATE TABLE IF NOT EXISTS post (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    title VARCHAR(80) NOT NULL,
    content VARCHAR(5000) NOT NULL,
    content_type TINYINT NOT NULL DEFAULT 1,
    shop_id BIGINT,
    deal_id BIGINT,
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    repost_count INT NOT NULL DEFAULT 0,
    audit_status TINYINT NOT NULL DEFAULT 0,
    audit_remark VARCHAR(255) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_post_public ON post(region, audit_status, status, is_deleted, created_at, id);
CREATE INDEX IF NOT EXISTS idx_post_user ON post(user_id, region, is_deleted, created_at, id);

CREATE TABLE IF NOT EXISTS post_image (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    url VARCHAR(255) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_post_image_post ON post_image(post_id, sort_no, id);

CREATE TABLE IF NOT EXISTS topic (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(8) NOT NULL,
    name VARCHAR(64) NOT NULL,
    post_count INT NOT NULL DEFAULT 0,
    follower_count INT NOT NULL DEFAULT 0,
    recommended BOOLEAN NOT NULL DEFAULT FALSE,
    pinned_sort INT NOT NULL DEFAULT 0,
    merged_to_id BIGINT NULL,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_topic_region_name ON topic(region, name);
CREATE INDEX IF NOT EXISTS idx_topic_region_public ON topic(region, status, merged_to_id, recommended, pinned_sort, id);

CREATE TABLE IF NOT EXISTS post_topic (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    topic_id BIGINT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_post_topic ON post_topic(post_id, topic_id);

CREATE TABLE IF NOT EXISTS topic_follow (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    topic_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_topic_follow ON topic_follow(topic_id, user_id);
CREATE INDEX IF NOT EXISTS idx_topic_follow_user ON topic_follow(user_id, created_at, id);

CREATE TABLE IF NOT EXISTS topic_hot_snapshot (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    topic_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    score BIGINT NOT NULL DEFAULT 0,
    post_count_7d INT NOT NULL DEFAULT 0,
    like_count_7d INT NOT NULL DEFAULT 0,
    comment_count_7d INT NOT NULL DEFAULT 0,
    calculated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_topic_hot_snapshot ON topic_hot_snapshot(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_hot_region_score ON topic_hot_snapshot(region, score, topic_id);

CREATE TABLE IF NOT EXISTS post_like (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_post_like ON post_like(post_id, user_id);

CREATE TABLE IF NOT EXISTS post_repost (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_post_repost_user ON post_repost(post_id, user_id);
CREATE INDEX IF NOT EXISTS idx_post_repost_user ON post_repost(user_id, created_at, id);

CREATE TABLE IF NOT EXISTS post_comment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    content VARCHAR(500) NOT NULL,
    parent_id BIGINT NOT NULL DEFAULT 0,
    reply_to BIGINT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_post_comment_post ON post_comment(post_id, status, is_deleted, parent_id, created_at, id);

CREATE TABLE IF NOT EXISTS post_report (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    reporter_user_id BIGINT NOT NULL,
    reporter_user_name VARCHAR(64) NOT NULL,
    reason VARCHAR(200) NOT NULL,
    status TINYINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_post_report_user ON post_report(post_id, reporter_user_id);

CREATE TABLE IF NOT EXISTS audit_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    biz_type TINYINT NOT NULL,
    biz_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    machine_result TINYINT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 0,
    auditor_id BIGINT NOT NULL DEFAULT 0,
    remark VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_task_region_status ON audit_task(region, biz_type, status, id);
CREATE INDEX IF NOT EXISTS idx_audit_task_biz_status ON audit_task(biz_type, biz_id, status, id);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL,
    action VARCHAR(64) NOT NULL,
    target VARCHAR(64) NOT NULL DEFAULT '',
    detail VARCHAR(1000) NOT NULL DEFAULT '',
    ip VARCHAR(45) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_log_admin ON audit_log(admin_id, created_at);

CREATE TABLE IF NOT EXISTS privacy_export_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    scope_json CLOB NOT NULL,
    format VARCHAR(16) NOT NULL DEFAULT 'zip',
    status TINYINT NOT NULL DEFAULT 0,
    file_name VARCHAR(255) NOT NULL DEFAULT '',
    file_path VARCHAR(512) NOT NULL DEFAULT '',
    expire_at TIMESTAMP NULL,
    fail_reason VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_privacy_export_task_user_created ON privacy_export_task(user_id, created_at, id);
CREATE INDEX IF NOT EXISTS idx_privacy_export_task_user_status ON privacy_export_task(user_id, status, id);

CREATE TABLE IF NOT EXISTS privacy_delete_task (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    verify_type VARCHAR(16) NOT NULL,
    account_snapshot VARCHAR(128) NOT NULL,
    reason VARCHAR(255) NOT NULL,
    status TINYINT NOT NULL DEFAULT 1,
    cooling_off_expire_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_privacy_delete_task_user_created ON privacy_delete_task(user_id, created_at, id);
CREATE INDEX IF NOT EXISTS idx_privacy_delete_task_user_status ON privacy_delete_task(user_id, status, id);

CREATE TABLE IF NOT EXISTS user_policy_accept_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    policy_type TINYINT NOT NULL,
    version VARCHAR(32) NOT NULL,
    locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN',
    source TINYINT NOT NULL DEFAULT 1,
    request_ip VARCHAR(45) NOT NULL DEFAULT '',
    user_agent VARCHAR(255) NOT NULL DEFAULT '',
    accepted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_policy_accept_user_type ON user_policy_accept_log(user_id, policy_type, id);
CREATE INDEX IF NOT EXISTS idx_policy_accept_type_version ON user_policy_accept_log(policy_type, version, id);

CREATE TABLE IF NOT EXISTS user_device (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_uid VARCHAR(128) NOT NULL,
    platform TINYINT NOT NULL,
    push_channel TINYINT NOT NULL DEFAULT 0,
    push_token VARCHAR(255) NOT NULL DEFAULT '',
    app_version VARCHAR(32) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    last_active_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_device_uid UNIQUE(device_uid)
);
CREATE INDEX IF NOT EXISTS idx_user_device_user_status ON user_device(user_id, status, id);

CREATE TABLE IF NOT EXISTS app_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(64) NOT NULL DEFAULT '',
    avatar VARCHAR(255) NOT NULL DEFAULT '',
    email VARCHAR(128),
    phone VARCHAR(32),
    password_hash VARCHAR(100),
    gender TINYINT NOT NULL DEFAULT 0,
    signature VARCHAR(255) NOT NULL DEFAULT '',
    preferred_region VARCHAR(8) NOT NULL DEFAULT 'CN',
    growth_value INT NOT NULL DEFAULT 0,
    level TINYINT NOT NULL DEFAULT 1,
    points INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_app_user_email ON app_user(email);
CREATE UNIQUE INDEX IF NOT EXISTS uk_app_user_phone ON app_user(phone);

CREATE TABLE IF NOT EXISTS user_expert_certification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    reason VARCHAR(500) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 1,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP NULL,
    audited_at TIMESTAMP NULL,
    effective_start_at TIMESTAMP NULL,
    effective_end_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_user_expert_certification_user_region
    ON user_expert_certification(user_id, region);
CREATE INDEX IF NOT EXISTS idx_user_expert_certification_region_status
    ON user_expert_certification(region, status, user_id);

CREATE TABLE IF NOT EXISTS user_follow (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    follower_user_id BIGINT NOT NULL,
    followed_user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_follow UNIQUE (follower_user_id, followed_user_id)
);
CREATE INDEX IF NOT EXISTS idx_user_follow_followed ON user_follow(followed_user_id, created_at, id);
CREATE INDEX IF NOT EXISTS idx_user_follow_follower ON user_follow(follower_user_id, created_at, id);

CREATE TABLE IF NOT EXISTS growth_points_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    type TINYINT NOT NULL,
    action VARCHAR(32) NOT NULL,
    biz_id BIGINT NOT NULL DEFAULT 0,
    change_amount INT NOT NULL,
    balance_after INT NOT NULL,
    remark VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS growth_rule (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(32) NOT NULL,
    action_name VARCHAR(64) NOT NULL,
    growth_value INT NOT NULL DEFAULT 0,
    points INT NOT NULL DEFAULT 0,
    daily_limit INT NOT NULL DEFAULT 0,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_growth_rule_action UNIQUE(action)
);

CREATE TABLE IF NOT EXISTS level_config (
    level TINYINT PRIMARY KEY,
    min_growth INT NOT NULL,
    level_name VARCHAR(32) NOT NULL,
    icon VARCHAR(255) NOT NULL DEFAULT '',
    privilege_json VARCHAR(2000) NOT NULL DEFAULT '{}',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS deal (id BIGINT AUTO_INCREMENT PRIMARY KEY, shop_id BIGINT NOT NULL, merchant_id BIGINT NOT NULL, region VARCHAR(8) NOT NULL, type TINYINT NOT NULL DEFAULT 1, title VARCHAR(128) NOT NULL, cover_image VARCHAR(255) NOT NULL DEFAULT '', price DECIMAL(10,2) NOT NULL, original_price DECIMAL(10,2) NOT NULL, currency CHAR(3) NOT NULL, stock INT NOT NULL DEFAULT 0, sold_count INT NOT NULL DEFAULT 0, valid_start DATE, valid_end DATE, rules VARCHAR(2000) NOT NULL DEFAULT '', audit_status TINYINT NOT NULL DEFAULT 1, status TINYINT NOT NULL DEFAULT 1, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, is_deleted BOOLEAN NOT NULL DEFAULT FALSE);
CREATE TABLE IF NOT EXISTS deal_item (id BIGINT AUTO_INCREMENT PRIMARY KEY, deal_id BIGINT NOT NULL, name VARCHAR(128) NOT NULL, quantity INT NOT NULL DEFAULT 1, price DECIMAL(10,2) NOT NULL DEFAULT 0, sort INT NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS `order` (id BIGINT AUTO_INCREMENT PRIMARY KEY, order_no VARCHAR(32) NOT NULL UNIQUE, user_id BIGINT NOT NULL, deal_id BIGINT NOT NULL, shop_id BIGINT NOT NULL, region VARCHAR(8) NOT NULL, quantity INT NOT NULL, unit_price DECIMAL(10,2) NOT NULL, amount DECIMAL(10,2) NOT NULL, currency CHAR(3) NOT NULL, pay_method VARCHAR(16) NOT NULL DEFAULT '', pay_status TINYINT NOT NULL DEFAULT 0, status TINYINT NOT NULL DEFAULT 1, paid_at TIMESTAMP NULL, expire_at TIMESTAMP NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS payment (id BIGINT AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL, order_no VARCHAR(32) NOT NULL, channel VARCHAR(16) NOT NULL, channel_txn VARCHAR(64) NOT NULL DEFAULT '', amount DECIMAL(10,2) NOT NULL, currency CHAR(3) NOT NULL, status TINYINT NOT NULL DEFAULT 0, raw_response VARCHAR(4000), created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT uk_payment_channel_txn UNIQUE(channel,channel_txn));
CREATE TABLE IF NOT EXISTS coupon (id BIGINT AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL, user_id BIGINT NOT NULL, deal_id BIGINT NOT NULL, shop_id BIGINT NOT NULL, code VARCHAR(32) NOT NULL UNIQUE, status TINYINT NOT NULL DEFAULT 1, verify_at TIMESTAMP NULL, verify_by BIGINT NOT NULL DEFAULT 0, expire_at DATE, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS refund (id BIGINT AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL UNIQUE, coupon_id BIGINT NOT NULL DEFAULT 0, amount DECIMAL(10,2) NOT NULL, reason VARCHAR(255) NOT NULL DEFAULT '', status TINYINT NOT NULL DEFAULT 0, audit_by BIGINT NOT NULL DEFAULT 0, audit_reason VARCHAR(255) NOT NULL DEFAULT '', audited_at TIMESTAMP NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS reservation_slot (id BIGINT AUTO_INCREMENT PRIMARY KEY,shop_id BIGINT NOT NULL,region VARCHAR(8) NOT NULL,biz_date DATE NOT NULL,start_time TIME NOT NULL,end_time TIME NOT NULL,capacity INT NOT NULL,reserved_count INT NOT NULL DEFAULT 0,confirm_mode TINYINT NOT NULL DEFAULT 2,cancel_before_minutes INT NOT NULL DEFAULT 120,enabled BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS reservation (id BIGINT AUTO_INCREMENT PRIMARY KEY,reservation_no VARCHAR(32) NOT NULL UNIQUE,user_id BIGINT NOT NULL,shop_id BIGINT NOT NULL,slot_id BIGINT NOT NULL DEFAULT 0,region VARCHAR(8) NOT NULL,reserve_time TIMESTAMP NOT NULL,people_count INT NOT NULL,contact_name VARCHAR(64) NOT NULL,contact_phone VARCHAR(32) NOT NULL,remark VARCHAR(255) NOT NULL DEFAULT '',status TINYINT NOT NULL DEFAULT 0,merchant_staff_id BIGINT NOT NULL DEFAULT 0,confirmed_at TIMESTAMP NULL,arrived_at TIMESTAMP NULL,cancelled_at TIMESTAMP NULL,rejected_at TIMESTAMP NULL,reschedule_count TINYINT NOT NULL DEFAULT 0,remind_status TINYINT NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS reservation_change_log (id BIGINT AUTO_INCREMENT PRIMARY KEY,reservation_id BIGINT NOT NULL,action_type TINYINT NOT NULL,operator_type TINYINT NOT NULL,operator_id BIGINT NOT NULL DEFAULT 0,from_status TINYINT NOT NULL DEFAULT 0,to_status TINYINT NOT NULL DEFAULT 0,old_reserve_time TIMESTAMP NULL,new_reserve_time TIMESTAMP NULL,remark VARCHAR(255) NOT NULL DEFAULT '',created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);

CREATE UNIQUE INDEX IF NOT EXISTS uk_growth_points_log_user_type_action_biz
    ON growth_points_log(user_id, type, action, biz_id);
CREATE INDEX IF NOT EXISTS idx_growth_points_log_user_created ON growth_points_log(user_id, id);

CREATE TABLE IF NOT EXISTS search_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL DEFAULT 'CN',
    keyword VARCHAR(128) NOT NULL,
    search_type TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_favorite (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    target_type TINYINT NOT NULL,
    target_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_favorite_target UNIQUE(user_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS idx_user_favorite_target ON user_favorite(target_type, target_id);

CREATE UNIQUE INDEX IF NOT EXISTS uk_search_history_user_region_keyword ON search_history(user_id, region, keyword);
CREATE INDEX IF NOT EXISTS idx_search_history_user_updated ON search_history(user_id, updated_at, id);

CREATE TABLE IF NOT EXISTS verification_code (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scene VARCHAR(32) NOT NULL,
    target_type TINYINT NOT NULL,
    target VARCHAR(128) NOT NULL,
    code_hash VARCHAR(100) NOT NULL,
    device_id VARCHAR(64) NOT NULL DEFAULT '',
    request_ip VARCHAR(45) NOT NULL DEFAULT '',
    status TINYINT NOT NULL DEFAULT 0,
    expire_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_verification_target_scene ON verification_code(target, scene, status);
CREATE INDEX IF NOT EXISTS idx_verification_expire_at ON verification_code(expire_at);

CREATE TABLE IF NOT EXISTS user_session (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    refresh_token_hash VARCHAR(100) NOT NULL,
    status TINYINT NOT NULL DEFAULT 1,
    refresh_expire_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_user_session_refresh_token_hash ON user_session(refresh_token_hash);
CREATE INDEX IF NOT EXISTS idx_user_session_user_id ON user_session(user_id, status);

CREATE TABLE IF NOT EXISTS user_ban_appeal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    account VARCHAR(128) NOT NULL DEFAULT '',
    reason VARCHAR(500) NOT NULL,
    status TINYINT NOT NULL DEFAULT 0,
    reject_reason VARCHAR(255) NOT NULL DEFAULT '',
    audit_by BIGINT NOT NULL DEFAULT 0,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_ban_appeal_user ON user_ban_appeal(user_id, status, id);
CREATE INDEX IF NOT EXISTS idx_user_ban_appeal_status ON user_ban_appeal(status, id);

CREATE TABLE IF NOT EXISTS import_batch (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    file_name VARCHAR(255) NOT NULL DEFAULT '',
    total INT NOT NULL DEFAULT 0,
    success INT NOT NULL DEFAULT 0,
    failed INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 0,
    error_file VARCHAR(255) NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rank_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rank_type TINYINT NOT NULL,
    region VARCHAR(8) NOT NULL DEFAULT 'CN',
    city_id BIGINT NOT NULL DEFAULT 0,
    category_id BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 1,
    calc_cycle TINYINT NOT NULL DEFAULT 4,
    weight_json VARCHAR(2000) NOT NULL,
    min_review_count INT NOT NULL DEFAULT 0,
    min_score DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    manual_intervene BOOLEAN NOT NULL DEFAULT TRUE,
    status TINYINT NOT NULL DEFAULT 0,
    effective_from TIMESTAMP NULL,
    effective_to TIMESTAMP NULL,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_rank_config_scope_version UNIQUE(rank_type, region, city_id, category_id, version)
);

CREATE TABLE IF NOT EXISTS rank (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    type TINYINT NOT NULL,
    region VARCHAR(8) NOT NULL DEFAULT 'CN',
    city_id BIGINT NOT NULL DEFAULT 0,
    category_id BIGINT NOT NULL DEFAULT 0,
    config_id BIGINT NOT NULL DEFAULT 0,
    period VARCHAR(16) NOT NULL DEFAULT '',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rank_region_city ON rank(region, city_id, type);

CREATE TABLE IF NOT EXISTS rank_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rank_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    position INT NOT NULL DEFAULT 0,
    score DECIMAL(10,2) NOT NULL DEFAULT 0,
    reason VARCHAR(255) NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_rank_item_rank ON rank_item(rank_id, position);

CREATE TABLE IF NOT EXISTS user_notification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    actor_user_id BIGINT NULL,
    region VARCHAR(8) NOT NULL,
    type VARCHAR(64) NOT NULL,
    title VARCHAR(128) NOT NULL,
    content VARCHAR(500) NOT NULL DEFAULT '',
    link_url VARCHAR(255) NOT NULL DEFAULT '',
    aggregate_count INT NOT NULL DEFAULT 1,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_notification_user_region_read
    ON user_notification(user_id, region, is_read, id);

CREATE TABLE IF NOT EXISTS conversation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_a BIGINT NOT NULL, user_b BIGINT NOT NULL,
    last_message_id BIGINT NULL, last_message_preview VARCHAR(200) NOT NULL DEFAULT '',
    last_message_at TIMESTAMP NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT uk_conversation_users UNIQUE(user_a,user_b)
);
CREATE TABLE IF NOT EXISTS message (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, conversation_id BIGINT NOT NULL, from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL, content VARCHAR(2000) NOT NULL, is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP NULL, status TINYINT NOT NULL DEFAULT 1, is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_block (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL, blocked_user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT uk_user_block UNIQUE(user_id,blocked_user_id)
);
CREATE TABLE IF NOT EXISTS message_report (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, reporter_user_id BIGINT NOT NULL, target_type TINYINT NOT NULL,
    target_id BIGINT NOT NULL, reason VARCHAR(255) NOT NULL, status TINYINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_message_report UNIQUE(reporter_user_id,target_type,target_id)
);
CREATE INDEX IF NOT EXISTS idx_conversation_user_a ON conversation(user_a,last_message_at,id);
CREATE INDEX IF NOT EXISTS idx_conversation_user_b ON conversation(user_b,last_message_at,id);
CREATE INDEX IF NOT EXISTS idx_message_conversation ON message(conversation_id,id);
CREATE INDEX IF NOT EXISTS idx_message_unread ON message(to_user_id,is_read,id);
CREATE INDEX IF NOT EXISTS idx_user_block_blocked ON user_block(blocked_user_id,user_id);
CREATE INDEX IF NOT EXISTS idx_message_report_status ON message_report(status,id);

CREATE TABLE IF NOT EXISTS circle (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, region VARCHAR(8) NOT NULL, name VARCHAR(64) NOT NULL,
    description VARCHAR(500) NOT NULL DEFAULT '', cover_url VARCHAR(255) NOT NULL DEFAULT '',
    member_count INT NOT NULL DEFAULT 0, post_count INT NOT NULL DEFAULT 0, sort INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1, created_by BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE, CONSTRAINT uk_circle_region_name UNIQUE(region,name)
);
CREATE TABLE IF NOT EXISTS circle_member (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, circle_id BIGINT NOT NULL, user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, CONSTRAINT uk_circle_member UNIQUE(circle_id,user_id)
);
CREATE INDEX IF NOT EXISTS idx_circle_region_status_sort ON circle(region,status,is_deleted,sort,id);
CREATE INDEX IF NOT EXISTS idx_circle_member_user ON circle_member(user_id,circle_id);
ALTER TABLE post ADD COLUMN IF NOT EXISTS circle_id BIGINT NULL;
CREATE INDEX IF NOT EXISTS idx_post_circle_status ON post(circle_id,audit_status,status,is_deleted,id);
