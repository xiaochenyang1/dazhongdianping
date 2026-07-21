# 大众点评(仿)项目骨架

当前 M4 已闭环，M5 商户经营与通知、M6 Flutter 本地业务闭环均已落地。M7 已完成帖子（含转发/取消转发、评论盖楼、帖子正文/评论 `@提醒`）、本地达人认证、关注流、APP 私信、区域化官方圈子以及话题广场/7 天热榜：Flutter 可浏览、互动和关注话题，PC Web 只读，管理端可治理、合并和重算热榜，并完成 `topics` 隐私导出/注销治理。真实 FCM/APNs 推送、认证商户号、真实支付 SDK、Google Maps 与目标环境凭证联调仍属于后续阶段。

当前仓库已经按文档口径起好了前后端最小骨架，目录别再瞎长了，先按这个往下做。

## 目录结构

- `docs/`: 需求、架构、接口、库表、实施、上线、值班等文档。
- `backend/`: `Java 17 + Spring Boot + MyBatis` 后端骨架。
- `web/`: `Vue 3 + TypeScript + Vite` PC Web 骨架。
- `admin-web/`: `Vue 3 + TypeScript + Vite` 管理端运营后台，覆盖门店、Banner、分类/城市/商圈基础数据、审核、达人认证、榜单、成长、圈子和话题治理，以及审计日志、隐私任务、订单退款查询。
- `merchant-web/`: 独立商户工作台，覆盖注册、登录、资质、概览、门店、员工、预订、团购、订单退款、点评回复与申诉。
- `app/`: Flutter 欧洲版工程，已覆盖浏览、搜索、登录、点评、团购、预订、社区帖子、话题广场、用户中心、通知与 GDPR 隐私中心闭环。

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
- 管理端数据库 RBAC 基础已完成：管理员、角色、权限点、管理员-角色、角色-权限和管理员区域范围均已落库；`/auth/me` 返回实时身份、权限与 `CN/EU` 范围，菜单、路由和 API 按权限过滤。角色停用后旧 token 仍可访问 `auth/me`，但权限会在下一次请求重新计算并被收回，固定受限 API 返回 `403`，动态审核列表可返回 `200` 空结果；管理员账号停用后旧 token 才会在下一次请求返回 `401`，前端清理 `localStorage` 并回到登录页。`admin-web` 已提供管理员账号、角色权限、Banner、审计日志、隐私任务和订单退款查询页面。
- 管理端分类、城市和商圈治理已完成：`data:geo:read/write` 同时约束菜单、`/data/meta` 路由和管理 API，支持当前区域内 CRUD、排序、启停与受保护删除。公开元数据只展示启用项，显式使用停用 ID 的门店筛选返回空结果；历史门店详情仍保留原名称。管理端门店、导入、商户门店草稿/审核落库和榜单发布都会重新校验引用数据仍处于启用状态。
- PC Web 商户列表已接价格、评分、团购、营业状态筛选和服务端真实分页；门店点评列表支持最新/最热/评分排序、最低评分和带图/无图筛选；门店详情支持相似推荐、原生分享并带剪贴板降级；门店、公开点评、社区/圈子/话题公开页已接入客户端运行时 `canonical`、`robots`、Open Graph、Twitter Card 和 JSON-LD metadata，但尚未提供 SSR/预渲染产物。
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

话题热榜使用数据库快照，不依赖 Redis：统计最近 7 天公开帖子，固定公式为 `post_count_7d * 20 + like_count_7d * 3 + comment_count_7d * 5 + (recommended ? 100 : 0)`。置顶话题优先，普通话题再按分数、关注数、ID 排序；CN/EU 每小时独立增量重算，首次读取无快照时同步兜底，替换失败会回滚并保留旧快照。当前没有独立话题 Feed，也没有话题更新通知。
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
- 头部搜索建议 / 热词 / 登录用户搜索历史面板(MySQL fallback,不是 ES 终态)
- 登录弹层(密码登录 / 验证码登录 / 注册 / 找回密码)
- 游客访问受限页时自动拦截，登录后可回跳恢复当前受限页
- 我的资料页
- 我的资料页(含绑定账号 / 改密码)
- 我的点评页
- 成长值流水页
- 公开用户主页
- 隐私中心(数据导出、认证下载、删除申请、冷静期撤销)
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
3. 继续做真实移动推送、认证商户号，并推进真实第三方/目标环境联调；本地达人认证、帖子转发、评论盖楼、帖子正文/评论 `@提醒`、关注流、私信、官方圈子和话题广场/热榜已经落地。
