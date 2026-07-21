INSERT INTO category (id, parent_id, region, name, sort_no) VALUES
    (100, 0, 'CN', '美食', 1),
    (101, 100, 'CN', '川菜', 1),
    (102, 100, 'CN', '火锅', 2),
    (110, 0, 'CN', '休闲娱乐', 2),
    (111, 110, 'CN', '咖啡馆', 1),
    (200, 0, 'EU', 'Dining', 1),
    (201, 200, 'EU', 'Chinese', 1),
    (202, 200, 'EU', 'Cafe', 2),
    (210, 0, 'EU', 'Lifestyle', 2);

INSERT INTO city (id, code, region, name, sort_no) VALUES
    (1, 'SH', 'CN', '上海', 1),
    (2, 'BJ', 'CN', '北京', 2),
    (101, 'PAR', 'EU', 'Paris', 1),
    (102, 'BER', 'EU', 'Berlin', 2);

INSERT INTO area (id, city_id, region, name, sort_no) VALUES
    (11, 1, 'CN', '徐汇', 1),
    (12, 1, 'CN', '静安', 2),
    (21, 2, 'CN', '朝阳', 1),
    (22, 2, 'CN', '海淀', 2),
    (1011, 101, 'EU', 'Le Marais', 1),
    (1012, 101, 'EU', 'Latin Quarter', 2),
    (1021, 102, 'EU', 'Mitte', 1),
    (1022, 102, 'EU', 'Charlottenburg', 2);

INSERT INTO admin_user (id, account, password_hash, name, status) VALUES
    (1, 'admin', '$2a$10$jqOjtTNxITz7WmpfstWxMebmoVjEFr08kLMVWRbDH3GezWSJfnqhC', '系统管理员', 1);

INSERT INTO admin_role (id, code, name, description, status, built_in) VALUES
    (1, 'super_admin', '超级管理员', '维护管理员、角色和全站运营能力', 1, TRUE),
    (2, 'content_auditor', '内容审核员', '审核点评、帖子和商户点评申诉', 1, TRUE),
    (3, 'merchant_auditor', '商户审核员', '审核商户资质、团购和门店变更', 1, TRUE),
    (4, 'operations_manager', '运营管理员', '维护榜单、成长、圈子和话题', 1, TRUE),
    (5, 'data_operator', '数据管理员', '维护基础数据、门店、导入批次和搜索索引', 1, TRUE);

INSERT INTO admin_permission (id, code, name, category, permission_type, status) VALUES
    (1, 'dashboard:read', '查看控制台', 'dashboard', 1, 1),
    (2, 'audit:review:read', '查看点评审核', 'audit', 1, 1),
    (3, 'audit:review:write', '处理点评审核', 'audit', 2, 1),
    (4, 'audit:post:read', '查看帖子审核', 'audit', 1, 1),
    (5, 'audit:post:write', '处理帖子审核', 'audit', 2, 1),
    (6, 'audit:review_appeal:read', '查看商户点评申诉', 'audit', 1, 1),
    (7, 'audit:review_appeal:write', '处理商户点评申诉', 'audit', 2, 1),
    (8, 'audit:merchant_application:read', '查看商户资质', 'audit', 1, 1),
    (9, 'audit:merchant_application:write', '处理商户资质', 'audit', 2, 1),
    (10, 'audit:deal:read', '查看团购审核', 'audit', 1, 1),
    (11, 'audit:deal:write', '处理团购审核', 'audit', 2, 1),
    (12, 'audit:shop_change:read', '查看门店变更审核', 'audit', 1, 1),
    (13, 'audit:shop_change:write', '处理门店变更审核', 'audit', 2, 1),
    (14, 'data:shop:read', '查看门店数据', 'data', 1, 1),
    (15, 'data:shop:write', '维护门店数据', 'data', 2, 1),
    (16, 'data:shop:import', '导入门店数据', 'data', 2, 1),
    (17, 'data:import_batch:read', '查看导入批次', 'data', 1, 1),
    (18, 'data:search_index:write', '重建搜索索引', 'data', 2, 1),
    (19, 'operations:rank:read', '查看榜单规则', 'operations', 1, 1),
    (20, 'operations:rank:write', '维护榜单规则', 'operations', 2, 1),
    (21, 'operations:growth:read', '查看成长规则', 'operations', 1, 1),
    (22, 'operations:growth:write', '维护成长规则', 'operations', 2, 1),
    (23, 'operations:circle:read', '查看官方圈子', 'operations', 1, 1),
    (24, 'operations:circle:write', '维护官方圈子', 'operations', 2, 1),
    (25, 'operations:topic:read', '查看话题治理', 'operations', 1, 1),
    (26, 'operations:topic:write', '维护话题治理', 'operations', 2, 1),
    (27, 'system:admin:read', '查看管理员', 'system', 1, 1),
    (28, 'system:admin:write', '维护管理员', 'system', 2, 1),
    (29, 'system:role:read', '查看角色', 'system', 1, 1),
    (30, 'system:role:write', '维护角色', 'system', 2, 1),
    (31, 'system:permission:read', '查看权限点', 'system', 1, 1),
    (32, 'data:geo:read', '查看基础数据', 'data', 1, 1),
    (33, 'data:geo:write', '维护基础数据', 'data', 2, 1),
    (34, 'audit:expert_certification:read', '查看达人认证', 'audit', 1, 1),
    (35, 'audit:expert_certification:write', '处理达人认证', 'audit', 2, 1);

INSERT INTO admin_user_role (admin_id, role_id) VALUES (1, 1);
INSERT INTO admin_region_scope (admin_id, region) VALUES (1, 'CN'), (1, 'EU');
INSERT INTO admin_role_permission (role_id, permission_id) SELECT 1, id FROM admin_permission;
INSERT INTO admin_role_permission (role_id, permission_id) VALUES
    (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 34), (2, 35),
    (3, 1), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13),
    (4, 1), (4, 19), (4, 20), (4, 21), (4, 22), (4, 23), (4, 24), (4, 25), (4, 26),
    (5, 1), (5, 14), (5, 15), (5, 16), (5, 17), (5, 18), (5, 32), (5, 33);

INSERT INTO merchant (id, account, company_name, contact_name, contact_phone, region, audit_status, status, is_deleted) VALUES
    (1001, 'merchant_cn_hotpot@example.com', '沪上渝里餐饮', '王磊', '13800000001', 'CN', 1, 1, FALSE),
    (1002, 'merchant_cn_cafe@example.com', '弄堂咖啡工作室', '陈青', '13800000002', 'CN', 1, 1, FALSE),
    (2001, 'merchant_eu_sichuan@example.com', 'Maison Sichuan SARL', 'Lina', '+33123456789', 'EU', 1, 1, FALSE),
    (2002, 'merchant_eu_cafe@example.com', 'Mitte Bread GmbH', 'Noah', '+49301234567', 'EU', 1, 1, FALSE);

INSERT INTO merchant_application (
    id, merchant_id, license_url, legal_person, shop_photo_urls, status,
    reject_reason, audit_by, submitted_at, audited_at
) VALUES
    (10001, 1001, 'https://cdn.example.com/licenses/merchant-1001.png', '王磊', '["https://cdn.example.com/shops/1001/front.jpg"]', 1, '', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (10002, 1002, 'https://cdn.example.com/licenses/merchant-1002.png', '陈青', '["https://cdn.example.com/shops/1002/front.jpg"]', 1, '', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (20001, 2001, 'https://cdn.example.com/licenses/merchant-2001.png', 'Lina', '["https://cdn.example.com/shops/2001/front.jpg"]', 1, '', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (20002, 2002, 'https://cdn.example.com/licenses/merchant-2002.png', 'Noah', '["https://cdn.example.com/shops/2002/front.jpg"]', 1, '', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO merchant_role (id, code, name, permissions, status) VALUES
    (1, 'owner', '主账号', 'shop:view,shop:edit,staff:manage,deal:edit,coupon:verify,order:view,order:refund,review:reply,review:appeal,reservation:view,reservation:confirm,reservation:arrive,dashboard:view', 1),
    (11, 'store_manager', '店长', 'shop:view,shop:edit,deal:edit,order:view,order:refund,review:reply,review:appeal,reservation:view,reservation:confirm,reservation:arrive,dashboard:view', 1),
    (12, 'coupon_operator', '核销员', 'coupon:verify,shop:view,reservation:view,reservation:arrive', 1),
    (13, 'service_operator', '客服运营', 'shop:view,order:view,review:reply,review:appeal,reservation:view,reservation:confirm', 1);

INSERT INTO merchant_operator (id, merchant_id, account, password_hash, name, phone, email, operator_type, shop_scope_type, status, is_deleted) VALUES
    (11001, 1001, 'merchant_cn_hotpot@example.com', '$2a$10$7fHXsIct1JQL5H/MOEC.Z.G8N2zSOYBStbTgbSQI0D6tzes3SP6X6', '王磊', '13800000001', 'merchant_cn_hotpot@example.com', 1, 1, 1, FALSE),
    (11002, 1002, 'merchant_cn_cafe@example.com', '$2a$10$7fHXsIct1JQL5H/MOEC.Z.G8N2zSOYBStbTgbSQI0D6tzes3SP6X6', '陈青', '13800000002', 'merchant_cn_cafe@example.com', 1, 1, 1, FALSE),
    (12001, 2001, 'merchant_eu_sichuan@example.com', '$2a$10$7fHXsIct1JQL5H/MOEC.Z.G8N2zSOYBStbTgbSQI0D6tzes3SP6X6', 'Lina', '+33123456789', 'merchant_eu_sichuan@example.com', 1, 1, 1, FALSE),
    (12002, 2002, 'merchant_eu_cafe@example.com', '$2a$10$7fHXsIct1JQL5H/MOEC.Z.G8N2zSOYBStbTgbSQI0D6tzes3SP6X6', 'Noah', '+49301234567', 'merchant_eu_cafe@example.com', 1, 1, 1, FALSE);

INSERT INTO merchant_operator_role (operator_id, role_id) VALUES
    (11001, 1),
    (11002, 1),
    (12001, 1),
    (12002, 1);

INSERT INTO shop (id, merchant_id, category_id, city_id, area_id, latitude, longitude, region, name, cover_url, phone, score, taste_score, env_score, service_score, price_per_capita, currency, address, business_hours, summary, has_deal, open_now, status, is_deleted, tags) VALUES
    (10001, 1001, 102, 1, 11, 31.1952000, 121.4365000, 'CN', '渝里火锅徐汇店', 'https://placehold.co/1200x720/f97316/ffffff?text=CN+Hotpot', '021-61008888', 4.7, 4.8, 4.6, 4.7, 138.00, 'CNY', '上海市徐汇区漕溪北路88号', '10:00-22:00', '适合聚餐的川渝火锅，菜品稳定。', TRUE, TRUE, 1, FALSE, '火锅,聚餐,夜宵'),
    (10002, 1002, 111, 1, 12, 31.2297000, 121.4470000, 'CN', '弄堂咖啡实验室', 'https://placehold.co/1200x720/0f766e/ffffff?text=CN+Cafe', '021-62006666', 4.5, 4.4, 4.7, 4.6, 52.00, 'CNY', '上海市静安区常德路21号', '08:30-20:30', '白天办公、晚上放空都挺合适。', FALSE, TRUE, 1, FALSE, '咖啡,安静,办公'),
    (20001, 2001, 201, 101, 1011, 48.8570000, 2.3560000, 'EU', 'Maison Sichuan Paris', 'https://placehold.co/1200x720/7c3aed/ffffff?text=EU+Sichuan', '+33142345678', 4.6, 4.7, 4.4, 4.5, 36.00, 'EUR', '12 Rue du Temple, Paris', '11:30-22:30', '面向欧洲华人的川味馆子，出餐稳。', TRUE, TRUE, 1, FALSE, 'Chinese,Spicy,Family'),
    (20002, 2002, 202, 102, 1021, 52.5295000, 13.4010000, 'EU', 'Mitte Bread & Brew', 'https://placehold.co/1200x720/2563eb/ffffff?text=EU+Cafe', '+493087654321', 4.4, 4.2, 4.6, 4.5, 18.00, 'EUR', 'Rosenthaler Str. 18, Berlin', '07:30-19:00', '适合早餐和轻办公的社区咖啡馆。', FALSE, FALSE, 1, FALSE, 'Cafe,Breakfast,Remote');

INSERT INTO shop_photo (id, shop_id, image_url, sort_no) VALUES
    (1, 10001, 'https://placehold.co/800x520/f97316/ffffff?text=Hotpot+Hall', 1),
    (2, 10001, 'https://placehold.co/800x520/ea580c/ffffff?text=Signature+Soup', 2),
    (3, 10002, 'https://placehold.co/800x520/0f766e/ffffff?text=Coffee+Bar', 1),
    (4, 20001, 'https://placehold.co/800x520/7c3aed/ffffff?text=Sichuan+Dinner', 1),
    (5, 20002, 'https://placehold.co/800x520/2563eb/ffffff?text=Berlin+Brunch', 1);

INSERT INTO dish (id, shop_id, name, price, recommend_reason, sort_no) VALUES
    (1, 10001, '鲜毛肚', 42.00, '脆嫩稳定，锅底适配度高。', 1),
    (2, 10001, '手打虾滑', 36.00, '常年高点单率。', 2),
    (3, 10002, '手冲耶加雪菲', 38.00, '酸甜感清爽，适合下午。', 1),
    (4, 20001, '夫妻肺片', 12.00, '海外华人回头率高。', 1),
    (5, 20001, '麻婆豆腐', 14.00, '下饭型招牌。', 2),
    (6, 20002, 'Flat White', 4.50, '奶香和咖啡豆风味平衡。', 1);

INSERT INTO home_banner (id, city_id, region, title, subtitle, image_url, link_url, enabled, sort_no) VALUES
    (1, NULL, 'CN', '本周热卖门店', '先把首页、列表、详情打通', 'https://placehold.co/1440x560/111827/ffffff?text=CN+Home+Banner', '/shops?cityId=1', TRUE, 1),
    (2, NULL, 'EU', 'Paris 热门华人餐厅', '欧洲区先看可交付骨架', 'https://placehold.co/1440x560/1d4ed8/ffffff?text=EU+Home+Banner', '/shops?cityId=101', TRUE, 1);

INSERT INTO home_feed (id, city_id, shop_id, region, feed_type, title, subtitle, cover_url, enabled, sort_no) VALUES
    (1, 1, 10001, 'CN', 'shop', '今晚聚餐别瞎选', '热锅、人多、适合下班直接去。', 'https://placehold.co/720x460/f97316/ffffff?text=Shanghai+Feed', TRUE, 1),
    (2, 1, 10002, 'CN', 'shop', '适合坐一下午的咖啡馆', '安静、不赶人、位置还行。', 'https://placehold.co/720x460/0f766e/ffffff?text=Coffee+Feed', TRUE, 2),
    (3, 101, 20001, 'EU', 'shop', '巴黎华人聚餐备选', '想吃辣点这个不太会翻车。', 'https://placehold.co/720x460/7c3aed/ffffff?text=Paris+Feed', TRUE, 1),
    (4, 102, 20002, 'EU', 'shop', 'Berlin 轻办公咖啡点', '白天开会、写字都还行。', 'https://placehold.co/720x460/2563eb/ffffff?text=Berlin+Feed', TRUE, 2);

INSERT INTO app_user (
    id,
    nickname,
    avatar,
    email,
    phone,
    password_hash,
    gender,
    signature,
    preferred_region,
    growth_value,
    level,
    points,
    status,
    is_deleted
) VALUES
    (9001, '审评员阿木', 'https://placehold.co/200x200/f59e0b/ffffff?text=AM', 'demo.cn@example.com', NULL, '$2a$10$PcTbF7vUqwvHBYVVEUNj2OFhD5TWW0qQO30honHXc8MIx9tJ6ofuO', 1, 'H2 本地演示用户，方便直接看评论和点赞。', 'CN', 120, 4, 10, 1, FALSE),
    (9002, '欧洲咖啡客', 'https://placehold.co/200x200/2563eb/ffffff?text=EU', NULL, '+447700900999', '$2a$10$B5FJZ6qdFulpY0cPPxN.b.NS2f3t0oIjeiwSQBy6Np6mchCUIOHpm', 0, 'H2 本地演示用户，方便直接看欧洲区评论和点赞。', 'EU', 80, 3, 5, 1, FALSE);

INSERT INTO review (
    id,
    user_id,
    shop_id,
    region,
    user_name,
    content,
    score_overall,
    score_taste,
    score_env,
    score_service,
    cost,
    currency,
    like_count,
    comment_count,
    audit_status,
    audit_remark,
    status,
    created_at,
    updated_at,
    is_deleted,
    tags
) VALUES
    (1, 0, 10001, 'CN', '阿遥', '锅底香但不燥，毛肚很稳，适合带朋友来。', 4.8, 4.9, 4.6, 4.7, 138.00, 'CNY', 2, 2, 1, '', 1, TIMESTAMP '2026-07-01 18:30:00', TIMESTAMP '2026-07-01 18:30:00', FALSE, '火锅,朋友聚餐'),
    (2, 0, 10002, 'CN', 'Milo', '工作日下午人不算太夸张，手冲和甜点都在线。', 4.4, 4.3, 4.6, 4.5, 52.00, 'CNY', 1, 1, 1, '', 1, TIMESTAMP '2026-07-02 14:20:00', TIMESTAMP '2026-07-02 14:20:00', FALSE, '咖啡,下午茶'),
    (3, 0, 20001, 'EU', 'Lina', '巴黎想找正经川菜，这家至少不会让人翻白眼。', 4.7, 4.8, 4.4, 4.6, 36.00, 'EUR', 1, 1, 1, '', 1, TIMESTAMP '2026-07-03 19:10:00', TIMESTAMP '2026-07-03 19:10:00', FALSE, 'Chinese,Spicy'),
    (4, 0, 20002, 'EU', 'Noah', '适合带电脑来待一上午，咖啡豆偏坚果风味。', 4.3, 4.2, 4.5, 4.4, 18.00, 'EUR', 0, 0, 1, '', 1, TIMESTAMP '2026-07-04 10:45:00', TIMESTAMP '2026-07-04 10:45:00', FALSE, 'Cafe,Remote');

INSERT INTO review_like (id, review_id, user_id, created_at) VALUES
    (1, 1, 9001, TIMESTAMP '2026-07-01 19:00:00'),
    (2, 1, 9002, TIMESTAMP '2026-07-01 19:10:00'),
    (3, 2, 9001, TIMESTAMP '2026-07-02 15:00:00'),
    (4, 3, 9002, TIMESTAMP '2026-07-03 20:00:00');

INSERT INTO review_comment (
    id,
    review_id,
    user_id,
    user_name,
    content,
    status,
    created_at,
    updated_at,
    is_deleted
) VALUES
    (1, 1, 9001, '审评员阿木', '锅底和毛肚这两个点说得挺实在，我也觉得这家适合带朋友来。', 1, TIMESTAMP '2026-07-01 19:20:00', TIMESTAMP '2026-07-01 19:20:00', FALSE),
    (2, 1, 9002, '欧洲咖啡客', '这种评价比那种空喊“绝绝子”的强多了，至少看得出真吃了。', 1, TIMESTAMP '2026-07-01 20:00:00', TIMESTAMP '2026-07-01 20:00:00', FALSE),
    (3, 2, 9001, '审评员阿木', '这家下午办公确实合适，就是高峰时段座位得碰运气。', 1, TIMESTAMP '2026-07-02 15:10:00', TIMESTAMP '2026-07-02 15:10:00', FALSE),
    (4, 3, 9002, '欧洲咖啡客', '巴黎能吃到不翻车的川菜已经很难得了，这条评价不算夸张。', 1, TIMESTAMP '2026-07-03 20:20:00', TIMESTAMP '2026-07-03 20:20:00', FALSE);

INSERT INTO audit_task (
    id,
    biz_type,
    biz_id,
    region,
    machine_result,
    status,
    auditor_id,
    remark,
    created_at,
    updated_at
) VALUES
    (1, 3, 1, 'CN', 0, 2, 0, '任务失效：点评已编辑，等待最新版本审核', TIMESTAMP '2026-07-01 18:20:00', TIMESTAMP '2026-07-01 18:25:00');

UPDATE shop SET review_count = 1 WHERE id IN (10001, 10002, 20001, 20002);

INSERT INTO rank_config (id, rank_type, region, city_id, category_id, version, calc_cycle, weight_json, min_review_count, min_score, manual_intervene, status, effective_from, updated_by) VALUES
    (3001, 1, 'CN', 1, 102, 1, 4, '{"score":0.70,"reviewCount":0.20,"hasDeal":0.10}', 1, 4.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1),
    (3002, 2, 'CN', 1, 111, 1, 4, '{"score":0.80,"reviewCount":0.20}', 1, 4.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1),
    (3003, 3, 'CN', 1, 111, 1, 2, '{"reviewCount":0.70,"hasDeal":0.30}', 0, 0.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1),
    (3101, 1, 'EU', 101, 201, 1, 4, '{"score":0.70,"reviewCount":0.20,"hasDeal":0.10}', 1, 4.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1),
    (3102, 2, 'EU', 101, 201, 1, 4, '{"score":0.80,"reviewCount":0.20}', 1, 4.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1),
    (3103, 3, 'EU', 101, 201, 1, 2, '{"reviewCount":0.70,"hasDeal":0.30}', 0, 0.00, TRUE, 1, TIMESTAMP '2026-07-01 00:00:00', 1);

INSERT INTO rank (id, name, type, region, city_id, category_id, config_id, period, enabled, updated_at) VALUES
    (30001, '上海火锅必吃榜', 1, 'CN', 1, 102, 3001, '2026-Q3', TRUE, TIMESTAMP '2026-07-01 00:00:00'),
    (30002, '上海咖啡好评榜', 2, 'CN', 1, 111, 3002, '2026-Q3', TRUE, TIMESTAMP '2026-07-01 00:00:00'),
    (30003, '上海咖啡热门榜', 3, 'CN', 1, 111, 3003, '2026-W28', TRUE, TIMESTAMP '2026-07-01 00:00:00'),
    (31001, '巴黎华人必吃榜', 1, 'EU', 101, 201, 3101, '2026-Q3', TRUE, TIMESTAMP '2026-07-01 00:00:00'),
    (31002, '巴黎华人好评榜', 2, 'EU', 101, 201, 3102, '2026-Q3', TRUE, TIMESTAMP '2026-07-01 00:00:00'),
    (31003, '巴黎华人热门榜', 3, 'EU', 101, 201, 3103, '2026-W28', TRUE, TIMESTAMP '2026-07-01 00:00:00');

INSERT INTO rank_item (id, rank_id, shop_id, position, score, reason) VALUES
    (300001, 30001, 10001, 1, 94.70, '综合评分 4.7，聚餐口碑稳定且当前有优惠。'),
    (300002, 30002, 10002, 1, 90.50, '评分稳定，环境体验突出。'),
    (300003, 30003, 10002, 1, 81.00, '近期点评活跃，适合办公与下午茶。'),
    (310001, 31001, 20001, 1, 93.60, '巴黎川味口碑稳定，当前有优惠。'),
    (310002, 31002, 20001, 1, 91.80, '综合评分与口味分领先。'),
    (310003, 31003, 20001, 1, 82.00, '华人聚餐热度稳定。');

INSERT INTO growth_rule (id, action, action_name, growth_value, points, daily_limit, enabled) VALUES
    (1, 'review_create', '发布点评', 10, 5, 5, TRUE),
    (2, 'review_liked', '点评获赞', 2, 1, 20, TRUE),
    (3, 'review_image', '上传点评图片', 3, 1, 10, TRUE),
    (4, 'order_complete', '完成订单', 20, 10, 0, TRUE);

INSERT INTO level_config (level, min_growth, level_name, icon, privilege_json, enabled) VALUES
    (1, 0, '新手', '', '{}', TRUE), (2, 20, '探索者', '', '{}', TRUE),
    (3, 50, '分享家', '', '{}', TRUE), (4, 100, '资深食客', '', '{}', TRUE),
    (5, 200, '城市达人', '', '{}', TRUE), (6, 500, '生活专家', '', '{}', TRUE),
    (7, 1000, '首席体验官', '', '{}', TRUE), (8, 2000, '城市传奇', '', '{}', TRUE);

INSERT INTO deal (id,shop_id,merchant_id,region,type,title,cover_image,price,original_price,currency,stock,sold_count,valid_start,valid_end,rules,audit_status,status,is_deleted) VALUES
 (40001,10001,1001,'CN',1,'双人川渝火锅套餐','https://placehold.co/1200x720/f97316/ffffff?text=Hotpot+Deal',88.00,156.00,'CNY',20,12,DATE '2026-07-01',DATE '2026-12-31','周末通用；需提前预约；不可与其他优惠同享。',1,1,FALSE),
 (41001,20001,2001,'EU',1,'Sichuan Dinner for Two','https://placehold.co/1200x720/7c3aed/ffffff?text=Paris+Deal',32.00,48.00,'EUR',20,8,DATE '2026-07-01',DATE '2026-12-31','Reservation recommended; one coupon per person.',1,1,FALSE);
INSERT INTO deal_item (id,deal_id,name,quantity,price,sort) VALUES (400001,40001,'招牌鸳鸯锅底',1,48.00,1),(400002,40001,'荤素拼盘',1,108.00,2),(410001,41001,'Starter + Main',2,48.00,1);
INSERT INTO reservation_slot(id,shop_id,region,biz_date,start_time,end_time,capacity,reserved_count,confirm_mode,cancel_before_minutes,enabled) VALUES
 (50001,10001,'CN',DATE '2026-07-20',TIME '18:00:00',TIME '20:00:00',10,0,1,120,TRUE),
 (50002,10001,'CN',DATE '2026-07-21',TIME '19:00:00',TIME '21:00:00',10,0,2,120,TRUE),
 (51001,20001,'EU',DATE '2026-07-20',TIME '18:30:00',TIME '20:30:00',12,0,2,180,TRUE);
