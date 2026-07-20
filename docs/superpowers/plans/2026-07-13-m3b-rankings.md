# M3b 榜单实施计划

1. 先写 schema/seed 契约和公开榜单接口失败测试。
2. 增加 `rank_config`、`rank`、`rank_item` 的 H2/MySQL DDL 与演示数据。
3. 实现公开榜单 mapper、service、controller，验证区域/城市/分类隔离。
4. 先写管理规则草稿、发布、失败保旧、回滚测试，再实现事务服务。
5. 增加 admin-web 规则管理与 Web 榜单浏览入口。
6. 同步接口、数据库、状态、测试文档。
7. 跑后端全测、Web 全测与构建、后台构建和浏览器回归。
