# 大众点评(仿)项目骨架

当前 M4 已闭环，M5 商户经营与通知、M6 Flutter 本地业务闭环均已落地。M7 已完成帖子（含转发/取消转发、评论盖楼、帖子正文/评论 `@提醒`）、本地达人认证、认证商户号、关注流、APP 私信、区域化官方圈子以及话题广场/7 天热榜：Flutter 可浏览、互动和关注话题，PC Web 只读，管理端可治理、合并和重算热榜，并完成 `topics` 隐私导出/注销治理。真实 FCM/APNs 推送、真实支付 SDK、Google Maps 与目标环境凭证联调仍属于后续阶段。

当前仓库已经按文档口径起好了前后端最小骨架，目录别再瞎长了，先按这个往下做。

## 目录结构

- `docs/`: 需求、架构、接口、库表、实施、上线、值班等文档。
- `backend/`: `Java 17 + Spring Boot + MyBatis` 后端骨架。
- `web/`: `Vue 3 + TypeScript + Vite` PC Web 骨架。
- `admin-web/`: `Vue 3 + TypeScript + Vite` 管理端运营后台，覆盖门店、Banner、搜索热词、分类/城市/商圈基础数据、审核（含门店草稿与团购）、达人认证、榜单、成长、圈子和话题治理，以及审计日志、隐私任务、订单退款查询/平台仲裁/对账补偿和 C 端用户治理（查询/封禁/解封/封禁申诉审核）。
- `merchant-web/`: 独立商户工作台，覆盖注册、登录、资质、概览、门店草稿编辑/提交审核、员工、预订、团购创建/编辑/上下架、订单退款、券码核销、点评回复与申诉。
- `app/`: Flutter 欧洲版工程，已覆盖浏览、搜索、登录、封禁申诉、点评、团购、预订、社区帖子、话题广场、用户中心、通知与 GDPR 隐私中心闭环。

## 当前实现状态

截至 `2026-07-21`，当前代码不是 PPT 工程，已经有一套能在本地跑起来的最小闭环：

- `M1` 本地已完成：首页 / 列表 / 详情浏览，`CN / EU` 区域隔离，头部关键词搜索到商户列表(MySQL fallback,不是 ES 终态)，并已补公开搜索建议 / 热词 fallback 接口、登录用户搜索历史、历史清空入口和头部联想面板；管理端登录、门店 CRUD、种子导入、导入批次查询。
- `M2` 已完成后端认证 + 点评/审核/互动最小闭环，`web` 已接登录弹层、游客拦截恢复、写点评 / 改点评、我的点评、点评详情互动区、我的资料 / 账号绑定 / 改密码、成长值流水页、公开用户主页：验证码发送、注册、验证码/密码登录、重置密码、`refresh`、`logout`、`/user/me`、`PUT /user/profile`、`POST /user/bind`、`PUT /user/password`、`GET /user/:id`、`GET /user/growth/records`、写点评 / 改点评 / 删点评 / 看点评详情 / 我的点评、点赞 / 评论 / 举报、本地图片上传、审核任务通过 / 驳回、门店评分聚合回写；游客在点赞 / 评论 / 举报时触发登录，登录后会自动续执行原动作。
- `M3` 搜索、榜单、收藏与轻积分已落代码：`/api/c/v1/search/shops` 支持 MySQL/Elasticsearch provider、拼音/纠错/筛选/距离排序与索引重建/增量同步，CI 会启动 Elasticsearch 8 跑真实 smoke；榜单支持版本化发布/回滚，Web 已接榜单和门店收藏。
- 成长规则与等级配置已数据库化：奖励值、每日上限和 `Lv1-Lv8` 阈值由管理端配置，发点评、点评获赞、带图点评、完成订单四类奖励均已接入并按业务 ID 幂等；`GET /api/c/v1/user/growth/records` 支持分页查看流水。
- 隐私中心已补当前可用闭环：后端支持概览、数据导出任务、认证 ZIP 下载、账号删除申请、冷静期撤销和到期匿名化；真实可导出 `account/reviews/orders/reservations/favorites/posts/follows/messages/circles/topics`。注销会删除本人的话题关注并按真实关系回填 `follower_count`，不会误删帖子话题关系或热榜快照。
- `POST /api/c/v1/auth/send-code` 的验证码限流已经落地：按 `scene + account`、`deviceId`、`IP` 返回 `429 + Retry-After`；默认走本地内存，配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis sorted set 计数。
- `Idempotency-Key` 重复提交保护已接入：写请求带同 key + 同请求体会复用首个响应，同 key + 不同请求体返回 `409`；默认走本地内存，配置 `APP_STATE_STORE_PROVIDER=redis` 后可把幂等响应缓存放到 Redis。
- `/api/b/v1` 已从单配置账号升级为数据库账号：支持商户注册、资质提交/查询、运营审核、主账号/员工登录、数据库角色权限、指定门店范围、员工列表/创建/编辑/启停；停用 `merchant_operator` 后其旧 B 端 token 会失效。M5b1 已补预订分页/详情/改期、真实经营看板和门店范围校验；M5b2 已补团购列表/创建/编辑/审核后上下架、门店订单分页筛选和退款通过/驳回；M5b3 已补新建/修改门店完整草稿、相册/菜单快照、提交审核、通过整体应用、驳回重提和线上版本冲突保护；M5b4 已补点评列表、商家回复、点评申诉草稿/保存/提交和 `biz_type=6` 管理端申诉审核。
- M5 商户端已补齐当前 M5a 页面闭环：`merchant-web` 覆盖注册、登录、资质状态/提交/驳回重提、概览、门店、员工角色与门店范围、预订、团购、订单退款、点评回复/申诉；管理端新增商户资质审核和商户点评申诉专页；C 端新增通知列表、未读数、WebSocket ticket、实时推送与断线 REST 补偿。
- 管理端数据库 RBAC 基础已完成：管理员、角色、权限点、管理员-角色、角色-权限和管理员区域范围均已落库；`/auth/me` 返回实时身份、权限与 `CN/EU` 范围，菜单、路由和 API 按权限过滤。角色停用后旧 token 仍可访问 `auth/me`，但权限会在下一次请求重新计算并被收回，固定受限 API 返回 `403`，动态审核列表可返回 `200` 空结果；管理员账号停用后旧 token 才会在下一次请求返回 `401`，前端清理 `localStorage` 并回到登录页。`admin-web` 已提供管理员账号、角色权限、Banner、搜索热词、审计日志、隐私任务和订单退款查询/平台仲裁/对账补偿页面。
- 管理端分类、城市和商圈治理已完成：`data:geo:read/write` 同时约束菜单、`/data/meta` 路由和管理 API，支持当前区域内 CRUD、排序、启停与受保护删除。公开元数据只展示启用项，显式使用停用 ID 的门店筛选返回空结果；历史门店详情仍保留原名称。管理端门店、导入、商户门店草稿/审核落库和榜单发布都会重新校验引用数据仍处于启用状态。
- PC Web 商户列表已接价格、评分、团购、营业状态筛选和服务端真实分页；门店点评列表支持最新/最热/评分排序、最低评分和带图/无图筛选；门店详情支持相似推荐、原生分享并带剪贴板降级；门店、公开点评、社区/圈子/话题公开页已接入客户端运行时 `canonical`、`robots`、Open Graph、Twitter Card 和 JSON-LD metadata。`npm run build` 现会额外为首页、商户、榜单、活动、社区、圈子和话题入口生成可抓取 HTML、JSON-LD、`prerender-manifest.json`，配置 `PUBLIC_SITE_URL` 时同时生成绝对 canonical、`sitemap.xml` 和 `robots.txt`；提供 `PRERENDER_API_BASE_URL` 时，`npm run build:prerender:data` 还会按 `X-Region` 抓取真实门店、点评、帖子、榜单、活动、圈子和话题详情快照。常驻 SSR 服务和目标环境自动接入仍待补齐。
- M6 Flutter MVP 基线已落地：默认 EU、CN/EU 与语言切换、密码/验证码登录、安全会话、浏览/搜索/门店详情、团购下单、预订创建、用户中心、通知列表与 ACK、隐私导出/认证下载保存/删除申请/撤销；地图、真实支付和推送未配置时明确阻止冒充成功。
- M7 帖子、本地达人认证、转发、关注、私信、官方圈子和话题链路已落地：用户可在资料页提交/重提本地达人申请，管理端 `/audit/expert-certifications` 可按区域审核；公开用户主页、点评和帖子作者只有在“已通过且有效”时才展示 `code=local_expert,label=本地达人`。话题按 CN/EU 隔离，Flutter 提供推荐/热榜/已关注三 Tab 与关注写操作，帖子支持转发/取消转发，PC Web 仅提供推荐/热榜/详情只读页面，管理端支持筛选、改名、推荐、置顶、屏蔽、不可逆合并和手动重算。
- M4 团购交易已完成环境安全的模拟闭环：团购详情、有限库存原子扣减、下单、`alipay_mock`/`stripe_mock` 支付、SHA-256 回调验签与幂等、按数量发券、订单/券列表、取消和退款；真实支付 SDK 留在 M6 区域化阶段。
- M4 预订已完成：时段容量、自动/人工确认、创建、列表、详情、取消、改期、商户履约动作和变更时间线均已接入，Web 已提供在线预订和“我的预订”。
- 管理端种子导入失败时会生成真实本地错误明细文件，批次查询返回同一条 `errorFile` 路径。
- 当前后端默认运行配置已指向 `MySQL`；可直接导入 MySQL 的脚本已补到 `sql/mysql/`，并带公开点评、点评图片、点赞/评论演示数据、审核演示数据、`user_expert_certification` 表与 `audit:expert_certification:*` 权限种子，以及可直接密码登录的 C 端演示账号。`H2` 仍保留为 `h2` profile 和测试环境使用。
- 文件上传默认仍可本地落盘，也已接入 S3 兼容对象存储上传入口：配置 `APP_FILE_STORAGE_PROVIDER=s3`、`APP_S3_*` 后，`POST /api/c/v1/files/upload` 会上传到对象存储并返回公开 URL。
- `CI/CD` 已补本地复用脚本和 GitHub Actions:`scripts/ci/verify-all.ps1` 负责后端测试、Web/管理端/商户端测试与构建，以及可选 Flutter、MySQL、S3 兼容对象存储、Elasticsearch、浏览器冒烟 / E2E；`ci.yml` 当前同时起 MySQL 8、Redis 7、MinIO、Elasticsearch 8 服务,执行 `-IncludeMysqlSmoke -IncludeStorageSmoke -IncludeBrowserSmoke -IncludeElasticsearchSmoke`;`.github/workflows/nightly.yml` 已补定时夜跑和手工触发,会追加 `-IncludeBrowserE2E`;`.github/workflows/release.yml` 已补测试环境自动部署和 `pre/prod` 手工发版入口,`.github/workflows/rollback.yml` 已补手工回滚入口,配套 `package-release.ps1`、`deploy-release.ps1`、`rollback-release.ps1` 已落库。

完整的“已完成 / 部分完成 / 外部待验收”证据请看 `docs/当前已完成功能与SQL导入说明.md` 的“全局功能完成矩阵”；根 README 只保留启动入口和阶段摘要，不再重复维护第二套完成判断。

## 后端

位置: `backend/`

当前已包含:

- 统一响应体
- `X-Region` 区域上下文
- `traceId` 透传
- 全局异常处理
- MyBatis 查询层
- `MySQL` 默认运行配置
- `H2` 本地 profile / 测试数据
- 管理端最小登录与内存 token 会话
- 管理端门店 CRUD / 种子导入 / 导入批次查询
- C 端本地认证最小闭环(JWT access token + refresh token + mock 验证码 + `send-code` 限流,默认内存,可切 Redis)
- `M1` 公开浏览接口:
  - `GET /api/c/v1/categories`
  - `GET /api/c/v1/cities`
  - `GET /api/c/v1/cities/{cityId}/areas`
  - `GET /api/c/v1/home/banners`
  - `GET /api/c/v1/home/feed`
  - `GET /api/c/v1/shops`
  - `GET /api/c/v1/shops/{shopId}`
  - `GET /api/c/v1/shops/{shopId}/similar?limit=1..12`
  - `GET /api/c/v1/shops/{shopId}/reviews`
  - `GET /api/c/v1/search/suggest`
  - `GET /api/c/v1/search/hot`
  - `GET /api/c/v1/search/history`
  - `DELETE /api/c/v1/search/history`
- `M2` 已完成本地最小认证接口:
  - `POST /api/c/v1/auth/send-code`
  - `POST /api/c/v1/auth/register`
  - `POST /api/c/v1/auth/login/code`
  - `POST /api/c/v1/auth/login/password`
  - `POST /api/c/v1/auth/password/reset`
  - `POST /api/c/v1/auth/refresh`
  - `POST /api/c/v1/auth/logout`
  - `POST /api/c/v1/auth/ban-appeals`(封禁申诉提交,免登录+`appeal` 场景验证码)
  - `POST /api/c/v1/auth/ban-appeals/query`(封禁申诉进度查询,免登录+`appeal` 场景验证码)
  - `GET /api/c/v1/user/me`
  - `PUT /api/c/v1/user/profile`
  - `POST /api/c/v1/user/bind`
  - `PUT /api/c/v1/user/password`
  - `GET /api/c/v1/user/growth/records`
  - `GET /api/c/v1/user/{userId}`
- 隐私中心接口:
  - `GET /api/c/v1/privacy/overview`
  - `POST /api/c/v1/privacy/export-tasks`
  - `GET /api/c/v1/privacy/export-tasks`
  - `GET /api/c/v1/privacy/export-tasks/{taskId}`
  - `GET /api/c/v1/privacy/export-tasks/{taskId}/download`
  - `POST /api/c/v1/privacy/delete-tasks`
  - `POST /api/c/v1/privacy/delete-tasks/{taskId}/cancel`
- 话题 C 端接口（所有查询受 `X-Region` 隔离）:
  - `GET /api/c/v1/topics?sort=latest|recommended|hot`
  - `GET /api/c/v1/topics/hot`
  - `GET /api/c/v1/topics/following`
  - `GET /api/c/v1/topics/{id}`
  - `GET /api/c/v1/topics/{id}/posts`
  - `PUT /api/c/v1/topics/{id}/follow`
  - `DELETE /api/c/v1/topics/{id}/follow`
- 话题管理端接口:
  - `GET /api/admin/v1/topics`
  - `PUT /api/admin/v1/topics/{id}`
  - `PUT /api/admin/v1/topics/{id}/recommendation`
  - `PUT /api/admin/v1/topics/{id}/status`
  - `POST /api/admin/v1/topics/{id}/merge`
  - `POST /api/admin/v1/topics/recalculate-hot`

话题热榜使用数据库快照，不依赖 Redis：统计最近 7 天公开帖子，固定公式为 `post_count_7d * 20 + like_count_7d * 3 + comment_count_7d * 5 + (recommended ? 100 : 0)`。置顶话题优先，普通话题再按分数、关注数、ID 排序；CN/EU 每小时独立增量重算，首次读取无快照时同步兜底，替换失败会回滚并保留旧快照。当前没有独立话题 Feed；帖子审核通过后会向关联话题关注者发送 `topic.update` 站内通知（作者本人跳过、同帖多话题去重）。
- `POST /api/c/v1/auth/send-code` 当前已按 `scene + account`、`deviceId`、`IP` 做限流，超限返回 `429` 并带 `Retry-After`；默认走本地内存计数，`APP_STATE_STORE_PROVIDER=redis` 时走 Redis。
- `M2` 已完成本地点评 / 审核 / 互动最小接口:
  - `POST /api/c/v1/reviews`
  - `GET /api/c/v1/reviews/{reviewId}`
  - `POST /api/c/v1/reviews/{reviewId}/like`
  - `POST /api/c/v1/reviews/{reviewId}/comments`
  - `GET /api/c/v1/reviews/{reviewId}/comments`
  - `POST /api/c/v1/reviews/{reviewId}/report`
  - `GET /api/c/v1/user/reviews/{reviewId}`
  - `PUT /api/c/v1/reviews/{reviewId}`
  - `DELETE /api/c/v1/reviews/{reviewId}`
  - `GET /api/c/v1/user/reviews`
  - `GET /api/admin/v1/audit/tasks`
  - `GET /api/admin/v1/audit/logs`
  - `GET /api/admin/v1/orders`
  - `GET /api/admin/v1/users`
  - `GET /api/admin/v1/users/{userId}`
  - `PUT /api/admin/v1/users/{userId}/status`
  - `GET /api/admin/v1/privacy/tasks`
  - `POST /api/admin/v1/audit/tasks/{taskId}/pass`
  - `POST /api/admin/v1/audit/tasks/{taskId}/reject`
- `M7` 已完成帖子内容第一阶段接口:
  - `GET/POST /api/c/v1/posts`
  - `GET/PUT/DELETE /api/c/v1/posts/{postId}`
  - `GET /api/c/v1/user/posts`
  - `GET /api/c/v1/user/posts/{postId}`
  - `POST /api/c/v1/posts/{postId}/like`
  - `POST /api/c/v1/posts/{postId}/repost`
  - `DELETE /api/c/v1/posts/{postId}/repost`
  - `GET/POST /api/c/v1/posts/{postId}/comments`
  - `POST /api/c/v1/posts/{postId}/report`
- `M2` 已完成文件上传最小接口(默认本地落盘,可切 S3 兼容对象存储):
  - `POST /api/c/v1/files/upload`
  - `GET /api/c/v1/files/{fileName}`
- 公开点评查询当前只返回审核通过内容:
  - `GET /api/c/v1/shops/{shopId}/reviews?sort=latest|popular|score&minScore=4&hasImages=true|false`
  - `GET /api/c/v1/reviews/{reviewId}`
- 公开点评详情在带登录态访问时，会额外返回 `likedByCurrentUser`
- `M1` 管理端接口:
  - `POST /api/admin/v1/auth/login`
  - `GET /api/admin/v1/menus`
  - `GET /api/admin/v1/shops`
  - `GET /api/admin/v1/shops/{shopId}`
  - `POST /api/admin/v1/shops`
  - `PUT /api/admin/v1/shops/{shopId}`
  - `DELETE /api/admin/v1/shops/{shopId}`
  - `POST /api/admin/v1/import/shops`
  - `GET /api/admin/v1/import/batches`
  - `GET/POST /api/admin/v1/categories`
  - `PUT/DELETE /api/admin/v1/categories/{id}`
  - `PUT /api/admin/v1/categories/{id}/status`
  - `GET/POST /api/admin/v1/cities`
  - `PUT/DELETE /api/admin/v1/cities/{id}`
  - `PUT /api/admin/v1/cities/{id}/status`
  - `GET/POST /api/admin/v1/areas`
  - `PUT/DELETE /api/admin/v1/areas/{id}`
  - `PUT /api/admin/v1/areas/{id}/status`
- `B` 端已实现工作台接口:
  - `GET /api/b/v1/health`
  - `GET /api/b/v1/account/me`
  - `GET /api/b/v1/roles`
  - `GET /api/b/v1/shops`
  - `GET /api/b/v1/reservations`
  - `GET /api/b/v1/reservations/{reservationId}`
  - `POST /api/b/v1/reservations/{reservationId}/confirm`
  - `POST /api/b/v1/reservations/{reservationId}/reject`
  - `POST /api/b/v1/reservations/{reservationId}/reschedule`
  - `POST /api/b/v1/reservations/{reservationId}/arrive`
  - `POST /api/b/v1/reservations/{reservationId}/no-show`
  - `POST /api/b/v1/coupons/{code}/verify`
  - `GET /api/b/v1/dashboard`
  - `GET /api/b/v1/deals`
  - `POST /api/b/v1/deals`
  - `PUT /api/b/v1/deals/{dealId}`
  - `PUT /api/b/v1/deals/{dealId}/status`
  - `GET /api/b/v1/orders`
  - `POST /api/b/v1/orders/{orderId}/refund-audit`
  - `GET /api/b/v1/shop-changes`
  - `GET /api/b/v1/shop-changes/{changeId}`
  - `POST /api/b/v1/shops/change-drafts`
  - `POST /api/b/v1/shops/{shopId}/change-drafts`
  - `PUT /api/b/v1/shop-changes/{changeId}`
  - `PUT /api/b/v1/shop-changes/{changeId}/photos`
  - `PUT /api/b/v1/shop-changes/{changeId}/dishes`
  - `POST /api/b/v1/shop-changes/{changeId}/submit`
  - `GET /api/b/v1/reviews`
  - `PUT /api/b/v1/reviews/{reviewId}/reply`
  - `POST /api/b/v1/reviews/{reviewId}/appeal-drafts`
  - `PUT /api/b/v1/review-appeals/{appealId}`
  - `POST /api/b/v1/review-appeals/{appealId}/submit`

启动:

```powershell
cd backend
./mvnw.cmd spring-boot:run
```

验证:

```powershell
cd backend
./mvnw.cmd test
```

默认端口:

- `http://localhost:8080`
- 健康检查: `http://localhost:8080/actuator/health`
- H2 控制台: 使用 `h2` profile 时可访问 `http://localhost:8080/h2-console`

说明:

- 默认运行配置已经指向 `MySQL`。先用 `scripts/ci/mysql-smoke.ps1` 向全新的显式数据库名导入，再用 `APP_DB_HOST` / `APP_DB_PORT` / `APP_DB_NAME` / `APP_DB_USERNAME` / `APP_DB_PASSWORD` 覆盖连接信息。
- 需要临时走内存库时，用 `h2` profile 启动。

## 前端

位置: `web/`

当前已包含:

- 首页
- 商户列表页
- 商户详情页
- 头部搜索建议 / 热词 / 登录用户搜索历史面板（热词优先读运营配置，空表才 fallback；联想 / 历史仍是当前 MySQL 口径，不是 ES 终态）
- 登录弹层(密码登录 / 验证码登录 / 注册 / 找回密码)
- 游客访问受限页时自动拦截，登录后可回跳恢复当前受限页
- 我的资料页
- 我的资料页(含绑定账号 / 改密码)
- 我的点评页
- 成长值流水页
- 公开用户主页
- 隐私中心(账号、点评、订单、帖子、预订、收藏、足迹、关注、私信、圈子与话题数据导出，认证下载、删除申请、冷静期撤销)
- 华人社区只读列表与帖子详情(`/community`、`/community/posts/:id`)
- 点评详情页
- 点评详情页互动区(点赞 / 评论 / 举报)
- 商户详情页点评预览展示点赞数 + 评论数
- 写点评 / 编辑点评页(已接本地图片上传，带类型/大小校验)
- `CN / EU` 区域切换
- 城市切换
- 基于 `axios` 的 API 封装
- Vite 代理到本地后端

启动:

```powershell
cd web
npm install
npm run dev
```

构建:

```powershell
cd web
npm run build
```

生产构建建议同时提供公开站点源地址，构建会生成静态入口预渲染、站点地图和 robots 文件：

```powershell
$env:PUBLIC_SITE_URL = "https://www.example.com"
npm run build
```

动态公开详情可通过 `PRERENDER_ROUTE_MANIFEST` 指向额外 JSON 路由快照；未提供真实数据快照时不会生成虚假的详情页。

如果后端已经启动，可直接生成真实公开详情快照（示例使用 CN 区域）：

```powershell
$env:PRERENDER_API_BASE_URL = "http://localhost:8080"
$env:PRERENDER_REGION = "CN"
$env:PUBLIC_SITE_URL = "https://www.example.com"
npm run build:prerender:data
```

数据快照构建默认严格校验任一公开接口失败并终止；只有明确接受部分快照时才设置 `PRERENDER_STRICT=0`，构建日志会逐项输出跳过原因。

浏览器冒烟:

```powershell
cd web
npm run test:e2e
```

默认端口:

- `http://localhost:5173`

## 管理端前端

位置: `admin-web/`

当前已包含:

- 管理员登录页
- 控制台概览
- 门店管理列表 + 新建 / 编辑 / 删除
- 点评审核页(`/audit/reviews`)
- 商户点评申诉页(`/audit/review-appeals`)
- 帖子审核页(`/audit/posts`)
- 审计日志页(`/system/audit-logs`)
- 隐私任务页(`/system/privacy-tasks`)
- 订单退款页(`/data/orders`)
- 种子导入页 + 批次结果查看
- 数据库管理员登录与实时身份刷新(`/auth/me`)
- 管理员账号页(`/system/admins`)和角色权限页(`/system/roles`)
- 用户管理页(`/system/users`)：C 端用户列表筛选（关键词/ID/状态/区域）、详情内容统计、封禁（必填原因，立即吊销全部登录态）与解封，动作写入审计日志
- 按权限过滤的系统管理菜单、路由与 API 访问；管理员区域范围按 `CN/EU` 生效
- `CN / EU` 区域切换
- 基于 `axios` 的管理端 API 封装
- Vite 代理到本地后端

启动:

```powershell
cd admin-web
npm install
npm run dev
```

构建:

```powershell
cd admin-web
npm run build
```

默认端口:

- `http://localhost:5174`

## 已验证

- `2026-07-26` Flutter 账户设置四个真实动作已接通：基础资料保存、绑定验证码发送、邮箱/手机号绑定和密码更新均调用现有后端；页面提供必填与密码一致性校验、提交中防重、成功/失败反馈，并在资料或绑定成功后同步当前用户信息。账户设置、用户仓储与用户中心聚焦测试 `13` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `210` 条通过。

- `2026-07-26` Flutter 搜索发现面板补齐搜索历史分页：仓储保留 `page/pageSize/total`，用户可按需加载更多历史并按记录 ID 去重；新搜索后刷新第一页，删除和清空同步更新分页状态，游客仍按空历史处理。浏览仓储与搜索页聚焦测试 `14` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `208` 条通过。

- `2026-07-26` Flutter 新增分页黑名单管理：用户中心可查看已拉黑用户、按需加载后续页并按用户 ID 去重，也可逐项解除拉黑；操作失败保留现有列表。消息仓储、黑名单页与用户中心聚焦测试 `3` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `207` 条通过。

- `2026-07-26` Flutter 私信聊天页已接消息历史分页：最新一页继续按时间正序展示，后续页反转后插入现有记录前端并按消息 ID 去重；翻历史页不重复发送已读确认，加载失败保留当前聊天记录，发送新消息仍追加到末尾。消息仓储与页面聚焦测试 `5` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `206` 条通过。

- `2026-07-26` Flutter 私信会话列表已接后端分页：仓储保留 `page/pageSize/total`，页面可按需加载更多并按会话 ID 去重；下拉刷新回到第一页，加载更多失败不会清空已加载会话。消息仓储与页面聚焦测试 `4` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `205` 条通过。

- `2026-07-26` Flutter 隐私中心导出任务补齐历史分页：导出任务页模型保留 `page/pageSize/total`，页面加载更早任务时按任务 ID 去重且不重载协议、设备和删除申请；创建新任务后仍完整刷新回第一页。隐私仓储/中心页聚焦测试 `18` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `204` 条通过。
- `2026-07-26` Flutter 公开用户粉丝/关注列表补齐历史分页：关系页模型保留 `page/pageSize/total`，粉丝与关注页可加载更早用户、按用户 ID 去重，嵌套公开主页跳转保持不变。用户仓储/公开主页聚焦测试 `12` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `203` 条通过。
- `2026-07-26` Flutter 点评评论区补齐历史分页：仓储新增带 `page/pageSize/total` 的评论页 API 并保留原列表 API；详情页按顶层评论 ID 合并后续页并保留楼中楼回复，发布评论后重新加载第一页。点评仓储/详情页聚焦测试 `13` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `202` 条通过。
- `2026-07-26` Flutter 帖子评论区补齐历史分页：仓储新增带 `page/pageSize/total` 的评论页 API 并保留原列表 API；详情页按顶层评论 ID 合并后续页，完整保留每条评论的楼中楼回复树，发布评论后仍刷新第一页。社区仓储/页面聚焦测试 `20` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `201` 条通过。
- `2026-07-26` Flutter 门店搜索结果补齐历史分页：浏览仓储新增带 `page/pageSize/total` 的搜索页 API 并兼容原列表 API；搜索页保留当前关键词加载后续结果、按门店 ID 去重，热词、搜索历史与输入联想行为保持不变。浏览仓储/搜索页聚焦测试 `13` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `200` 条通过。
- `2026-07-26` Flutter 圈子成员补齐历史分页：仓储新增带 `page/pageSize/total` 的成员页 API 并保留原列表 API；成员页可加载更早成员、按用户 ID 去重，加载失败保留已有成员。圈子仓储/页面聚焦测试 `6` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `199` 条通过。
- `2026-07-26` Flutter 圈子详情公开帖子补齐历史分页：仓储新增带 `page/pageSize/total` 的帖子页 API 并保留原列表 API；详情页可加载更早帖子、按帖子 ID 去重，失败时保留已有内容。圈子仓储/页面聚焦测试 `5` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `198` 条通过。
- `2026-07-26` Flutter 同城圈子广场补齐历史分页：全部圈子和我加入的圈子共用带 `page/pageSize/total` 的页 API，原列表 API 保持兼容；页面可加载更早圈子、按圈子 ID 去重，加载失败保留已有内容。圈子仓储/页面聚焦测试 `4` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `197` 条通过。
- `2026-07-26` Flutter 话题详情公开帖子补齐历史分页：仓储新增带 `page/pageSize/total` 的帖子页 API 并保留原列表 API；详情页可加载更早帖子、按帖子 ID 去重，加载失败保留已有内容并提示。话题仓储/页面聚焦测试 `8` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `196` 条通过。
- `2026-07-26` Flutter 话题广场补齐历史分页：推荐、热榜和已关注三类仓储 API 保留 `page/pageSize/total`，各标签可独立加载更早话题并按话题 ID 去重；原列表 API 保持兼容，游客仍不会请求受保护的已关注接口。话题仓储/页面聚焦测试 `7` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `195` 条通过。
- `2026-07-26` Flutter 社区信息流补齐历史分页：仓储为推荐流、关注流和我的帖子新增带 `page/pageSize/total` 的页 API，同时保留原列表 API；推荐与关注标签可分别加载更早帖子、按帖子 ID 去重，加载失败保留已有内容。社区仓储/页面聚焦测试 `19` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `194` 条通过。
- `2026-07-26` Flutter 用户集合补齐历史分页：我的点评、我的帖子和收藏页保留后端 `page/pageSize/total`，可显式加载更早记录并按记录 ID 去重；订单、券、预订继续使用各自带状态筛选的分页页面。用户仓储/集合页聚焦测试 `16` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `193` 条通过。
- `2026-07-26` Flutter 浏览足迹已接后端分页：仓储新增保留 `page/pageSize/total` 的足迹页模型，同时兼容原列表 API；页面可加载更早足迹、按门店 ID 去重，加载失败保留已有结果，单条删除与清空会同步修正分页状态。浏览仓储/足迹页聚焦测试 `10` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `192` 条通过。
- `2026-07-26` Flutter 预订历史已接后端分页：仓储新增带 `page/pageSize/total` 的预订页模型，同时保留原列表 API；我的预订可按当前状态加载更早记录、合并时按预订 ID 去重，切换筛选会重新从第一页开始，加载失败保留已有结果并提示。预订仓储/列表页聚焦测试 `5` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `191` 条通过。
- `2026-07-26` Flutter 券历史已接后端分页：仓储新增带 `page/pageSize/total` 的券页模型，同时保留原列表 API；我的券可按当前状态加载更早记录、合并时按券 ID 去重，切换筛选会重新从第一页开始，加载失败保留已有结果并提示。交易仓储/券列表聚焦测试 `5` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `190` 条通过。
- `2026-07-26` Flutter 订单历史已接后端分页：仓储新增带 `page/pageSize/total` 的订单页模型，同时保留原列表 API；订单页可按当前支付状态加载更早记录、合并时按订单 ID 去重，切换筛选会重新从第一页开始，加载失败保留已有结果并提示。交易仓储/订单页聚焦测试 `5` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `189` 条通过。
- `2026-07-26` Flutter 通知中心已接后端分页：仓储保留 `page/pageSize/total`，列表按需加载更早通知并按 ID 去重；“只看未读”在当前页没有结果但后端仍有下一页时，可继续翻页查找未读消息，加载失败不会清空已加载内容。通知仓储与页面聚焦测试 `22` 条通过，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `188` 条通过。
- `2026-07-26` Flutter 通知中心补齐主动同步与未读筛选：新增“全部 / 只看未读”分段筛选、下拉刷新、空状态刷新，以及加载失败后的明确错误和重试入口；既有通知已读、全部已读和业务详情跳转保持不变。通知页面测试增至 `17` 条，`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `186` 条通过。
- `2026-07-26` Flutter 静态分析、列表刷新和全量测试基线已修复：预订仓储测试 fake 补齐查询参数，移除不可达 switch 分支和多余类型转换；订单、券、预订、榜单、活动五个列表不再让 `setState` 回调意外返回 `Future`，初始化也不再触发多余状态更新。同步校正懒加载视口、剪贴板平台通道、SnackBar 队列、本人点评 fixture 与帖子删除导航场景的测试。`flutter analyze` 零问题，`flutter test --concurrency=1` 全量 `182` 条通过。
- `2026-07-26` Flutter 封禁申诉入口已补齐：API 错误保留 `messageKey`，密码登录识别 `auth.user_banned` 后展示申诉引导；登录页也提供常驻入口。用户可免登录发送 `appeal` 场景验证码、提交 10-500 字申诉、查询最新审核进度并查看封禁原因/驳回说明，通过后可返回登录。相关 Dart 静态分析无问题，API、仓储、登录页与申诉页聚焦测试 `18` 条通过。
- `2026-07-25` PC Web SEO 预渲染与隐私导出模块对齐已完成聚焦验证：新增静态入口预渲染和 API 快照导出脚本，构建后可生成独立 HTML、canonical、Open Graph、Twitter Card、JSON-LD、制品清单，并在配置 `PUBLIC_SITE_URL` 时生成 sitemap/robots；带本地 H2 后端、`PRERENDER_REGION=CN` 的 `npm run build:prerender:data` 实测生成 15 个路由（7 个静态入口 + 8 个真实详情快照）。PC 隐私中心补齐后端已支持的 `browse_history/messages/circles/topics` 类型与勾选入口；SEO 快照脚本测试 5 条、Web 全量测试 117 条均通过。常驻 SSR、真实部署域名和目标环境联调仍未完成。
- `2026-07-24` 封禁申诉链路二轮优化已完成前后端联调与全量回归：申诉通过/驳回/管理员直接解封会给用户写 `account.ban_appeal` 站内通知（复用通知模块，含 WebSocket 推送与聚合逻辑），用户恢复登录后可在通知列表看到审核结果；申诉提交/查询响应带出最近一次 `user_ban` 审计日志的封禁原因，`web` 申诉面板展示"封禁原因"、申诉已通过时提供"回到密码登录"一键预填入口；管理端用户详情新增 `banReason`/`pendingAppealCount`/`latestAppealStatusText` 并支持一键跳转 `/audit/user-appeals`；全局兜底异常 handler 补错误日志，未匹配路径由兜底 `500` 修正为 `404 common.not_found`。`backend` `mvn test` 308 条通过；`web` `npm test` 78 条通过；`admin-web` `npm test` 61 条通过；三端 `vue-tsc`/`build` 通过。本地起 `h2` 后端实测：申诉响应带封禁原因、管理端详情联动字段正确、审核通过后用户登录可见"封禁申诉已通过"通知、错误路径返回 `404`。
- `2026-07-24` 用户封禁申诉链路本轮已完成前后端联调与全量回归：后端补齐 `biz_type=8` 统一审核（列表富化、通过自动解封、驳回记录原因、管理员直接解封自动了结待审申诉并使任务失效）、`POST /api/c/v1/auth/ban-appeals/query` 申诉进度查询、密码登录封禁改抛 `auth.user_banned`（与验证码登录/刷新一致）；`web` 登录弹层新增封禁识别（`ApiError.messageKey`）与申诉面板（发 `appeal` 验证码、提交、查进度），`admin-web` 新增 `/audit/user-appeals` 审核页并接入菜单/路由/权限（`audit:user_appeal:read/write`，种子权限 47/48）。`backend` 运行 `mvn test`，`308` 条测试通过（含新增 `UserBanAppealFlowTest` 4 条）；`web` 运行 `npm test`，`27` 个测试文件、`77` 条测试通过（含新增 `AuthDialog.test.ts` 4 条）；`admin-web` 运行 `npm test`，`22` 个测试文件、`60` 条测试通过（含新增 `UserAppealAuditView.test.ts` 3 条）。本地起 `h2` 后端 + 双前端 dev 经 Vite 代理实测全链路：封禁登录 `401 auth.user_banned` → 免登录发码提交申诉 → 管理端 `biz_type=8` 列表出现申诉（含用户昵称与理由）→ 通过后用户自动解封并可重新登录 → 申诉进度查询返回"已通过"。
- `2026-07-24` 管理端 C 端用户治理（用户查询/详情/封禁/解封）本轮已完成前后端联调与全量回归：`backend` 运行 `mvnw test`，`304` 条测试通过（含新增 `AdminAppUserControllerTest` 4 条）；`admin-web` 运行 `npm test`，`21` 个测试文件、`57` 条测试通过，`npm run build` 通过；本地起 `h2` 后端 + `admin-web` dev 通过 Vite 代理实测：封禁后旧 access token 立即 `401`、密码/验证码登录均被拦截并提示"账号已被封禁"、审计日志记录 `user_ban`/`user_unban`、解封后登录恢复。本轮同时修复 `loginWithCode` 对封禁用户的绕过问题，并给 `TopicHotRankingServiceTest` 补 `@AfterEach` 清理修复既有的测试顺序耦合。
- `2026-07-21` 管理端订单退款查询本轮已完成全量回归：`backend` 运行 `.\mvnw.cmd -q test`，`291` 条测试通过；`admin-web` 运行 `npm test`，`17` 个测试文件、`41` 条测试通过；`admin-web` 运行 `npm run build` 通过。
- `2026-07-21` 本轮按功能包执行了聚焦验证，而不是重跑全仓：`web` 运行 `npm test -- src/services/browse.test.ts src/views/ShopListView.test.ts src/views/ShopDetailView.test.ts src/views/ShopReviewsView.test.ts src/composables/useSeoMeta.test.ts src/views/CommunityView.test.ts src/views/ReviewDetailView.test.ts src/views/CircleViews.test.ts src/views/TopicViews.test.ts`，`9` 个测试文件、`38` 条测试通过；`npm run build` 通过。
- `merchant-web` 运行 `npm test -- src/layouts/MerchantLayout.test.ts src/services/merchant.test.ts src/views/OrdersView.test.ts src/views/ReservationsView.test.ts src/views/ReviewsView.test.ts`，`5` 个测试文件、`14` 条测试通过；`npm run build` 通过。
- `backend` 运行 `.\mvnw.cmd -q "-Dtest=PublicBrowseControllerTest" test` 与 `.\mvnw.cmd -q "-Dtest=UserPrivacyControllerTest,CommunityControllerTest" test`，均通过；`app` 运行社区/圈子/话题、首页和消息的 `flutter test` 聚焦用例均通过；`scripts/ci/test-browser-e2e.ps1` 契约通过。
- 上述结果只覆盖本轮切分并提交的功能，不替代全仓回归、真实 MySQL smoke、目标环境凭证联调或上线演练。

## MySQL 初始化 SQL

已补到 `sql/mysql/`:

- `sql/mysql/00_all_in_one.sql`: 已退役的安全阻断桩；执行时会直接报错，防止旧的一键命令无确认重置固定数据库。
- `sql/mysql/01_schema.sql`: 当前代码口径的 MySQL 建表脚本,已包含 `review_like`、`review_comment`、`review_report`、`growth_points_log`。
- `sql/mysql/02_seed_data.sql`: 当前浏览链路、公开点评、点评图片、点赞/评论演示数据、审核演示数据和 C 端演示账号初始化脚本。

如果你要看“哪个功能已经做完了、标在哪些文档、对应哪套 SQL”，直接看 `docs/当前已完成功能与SQL导入说明.md`，那份已经整理成对照表了。

安全导入命令（数据库名必须尚不存在）:

```powershell
.\scripts\ci\mysql-smoke.ps1 -DbName dazhongdianping_local
```

需要用独立临时库跑完整导库 + 后端冒烟，并在结束后清理本次新建的库时:

```powershell
.\scripts\ci\mysql-smoke.ps1 -DbName dazhongdianping_smoke -DropDatabaseAfter
```

注意:

- 这套脚本对应的是**当前已经落地的代码能力**,不是文档里未来大而全的终态库表。
- `mysql-smoke.ps1` 默认只向本轮新建的数据库导入 `01_schema.sql` 和 `02_seed_data.sql`;若同名库已存在会直接拒绝,可改用新的临时 `-DbName` 或对已准备好的库使用 `-SkipImport`。只有显式同时传入 `-DbName` 与 `-AllowDestructiveImport` 才允许重置既有库。`-DropDatabaseAfter` 同样必须配合显式 `-DbName`;只有本次执行实际创建且所有权标记仍匹配的库会在 `finally` 中删除。
- 会预置浏览数据、公开点评、点评图片、点赞/评论演示数据、待审 / 驳回审核案例和两个可直接密码登录的 C 端演示账号,方便你导库后直接演示当前已完成功能。
  - 点评互动相关表已经备好:`review_like`、`review_comment`、`review_report`;其中举报表默认等你实际点一次举报后再产生业务数据。
  - 搜索历史表 `search_history` 已备好,默认空表;登录用户带关键词搜索商户列表后会写入当前区域历史。
- 账号绑定 / 改密码 / 公开用户主页直接复用 `app_user`、`verification_code`、`review` 这些现有表,不需要额外补一套 SQL。
- 当前验证码限流和 `Idempotency-Key` 重复提交保护都不依赖额外 MySQL 表；默认走本地内存,配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis。
- 运行期表如 `verification_code`、`user_session`、`import_batch` 会建出来,但默认不预置运行数据。
- C 端演示账号:
  - 邮箱账号: `demo.cn@example.com` / `Demo123456`
  - 手机号账号: `+447700900999` / `Demo123456`
- 管理端初始演示账号来自 `sql/mysql/02_seed_data.sql` 的 `admin_user` 种子：`admin` / `admin123456`；数据库只保存 BCrypt `password_hash`，登录、角色、权限和 `CN/EU` 区域范围均从数据库加载。

## 下一步建议

1. `scripts/ci/mysql-smoke.ps1` 已于 `2026-07-12` 用临时 `MySQL 8` 实例 (`127.0.0.1:13306`) 实跑通过；宿主机 `MySQL80` 那套现成 root 凭证仍然不可用，但这已经不是仓库侧阻塞。后面如果你非要复用宿主机服务，先把凭证收拾明白。
2. 给目标环境的 `MySQL / Redis / S3` 和部署目标机补齐真实环境凭证、SSH secrets，并把现有发布 / 回滚流水线真正跑到目标环境上。
3. 继续做真实移动推送，并推进真实第三方/目标环境联调；本地达人认证、认证商户号、帖子转发、评论盖楼、帖子正文/评论 `@提醒`、关注流、私信、官方圈子和话题广场/热榜已经落地。
4. PC Web 已支持按区域抓取真实公开数据快照；下一步把快照生成接入发布流水线并补真实域名/缓存策略，再评估是否需要常驻 SSR 服务。
