# 当前已完成功能与 SQL 导入说明

> 最后更新:2026-07-21
> M7 补充：已完成帖子与转发、评论盖楼、帖子正文/评论 `@提醒`、本地达人认证、关注流、私信、官方圈子、区域化话题广场、7 天热榜、三端页面、管理端治理和话题隐私治理。
> 适用范围:当前仓库真实已落地的 `M1` 至 `M7` 本地闭环；真实欧洲支付、Google Maps、FCM/APNs、认证商户号和目标环境凭证联调仍未完成

## 1. 现在已经做完了什么

### 1.1 M1 浏览与管理端最小闭环

- C 端公开浏览已完成:首页 Banner/feed、商户列表、商户详情、城市/分类/商圈筛选、`CN / EU` 区域隔离。
- 头部关键词搜索已接到 `GET /api/c/v1/search/shops`:默认 provider 为 MySQL；配置 `APP_SEARCH_PROVIDER=elasticsearch` 后启用 ES 分词、拼音、纠错、组合筛选和距离排序。MySQL→ES 的重建、增量同步及真实 Elasticsearch 8 smoke 已落地。`GET /api/c/v1/search/suggest`、`GET /api/c/v1/search/hot`、登录用户搜索历史面板/清空和切区重拉也已接通。
- 管理端最小闭环已完成:管理员登录、门店 CRUD、种子导入、导入批次查询。
- `B` 端最小只读工作台已建立:当前提供 `GET /api/b/v1/health`、`GET /api/b/v1/account/me`、`GET /api/b/v1/roles`、`GET /api/b/v1/shops`;一期商户账号绑定单区域,`X-Region` 必须与商户经营区域一致,错区请求直接 `401`;完整入驻、员工、团购、预订等商户工作台能力仍不在 M1/M2。
- 对应后端接口已完成:
  - `GET /api/c/v1/categories`
  - `GET /api/c/v1/cities`
  - `GET /api/c/v1/cities/{cityId}/areas`
  - `GET /api/c/v1/home/banners`
  - `GET /api/c/v1/home/feed`
  - `GET /api/c/v1/shops`
  - `GET /api/c/v1/shops/{shopId}`
  - `GET /api/c/v1/shops/{shopId}/similar?limit=1..12`
  - `GET /api/c/v1/shops/{shopId}/reviews`
  - `POST /api/admin/v1/auth/login`
  - `GET /api/admin/v1/menus`
  - `GET/POST/PUT/DELETE /api/admin/v1/shops`
  - `POST /api/admin/v1/import/shops`
  - `GET /api/admin/v1/import/batches`

### 1.2 M2 认证、用户中心、点评互动审核最小闭环

- 认证已完成:验证码发送、注册、验证码登录、密码登录、重置密码、`refresh`、`logout`。
- 用户中心已完成:我的资料页、我的点评页、成长值流水页、公开用户主页、游客拦截恢复、游客互动登录后自动续执行、`GET /user/me`、`GET /user/expert-certification`、`POST /user/expert-certification/apply`、`PUT /user/profile`、`POST /user/bind`、`PUT /user/password`、`GET /user/:id`、`GET /user/growth/records`。
- 点评体系已完成:写点评、编辑点评、删除点评、公开点评详情、我的点评详情、点赞/取消点赞、评论发布/列表、举报点评、本地图片上传、管理端审核通过/驳回、门店评分聚合回写。
- 轻积分 / 等级已完成当前范围:发点评、点评获赞、带图点评和完成订单分别读取 `review_create/review_liked/review_image/order_complete` 规则，按用户、动作、类型和业务 ID 幂等写成长值/积分流水；等级按 `level_config` 阈值自动升级，管理端可维护成长规则与 `Lv1-Lv8`，`GET /user/growth/records` 可分页查看流水。
- 本地达人认证已完成:资料页支持提交和驳回后重提，状态口径为 `0未申请 1待审核 2已通过 3已驳回`；管理端达人认证审核复用统一审核中心 `audit_task.biz_type=7`，公开用户主页、点评和帖子作者只有“已通过且有效”时才展示 `code=local_expert,label=本地达人`。
- 前端页面已完成:
  - `web`: 登录弹层、头部搜索历史面板 / 清空、`CN / EU` 区域切换、我的资料(含达人申请 / 绑定账号 / 改密码)、我的点评、成长值流水、公开用户主页、独立门店点评列表、点评详情、点评详情互动区、写点评 / 编辑点评、本地图片上传、商户详情页点评预览点赞/评论数、门店相似推荐，以及公开页客户端运行时 SEO `canonical` / `robots` / Open Graph / Twitter Card / JSON-LD；构建已为 7 个静态公开入口生成可抓取 HTML、制品清单，并可在配置公开域名时生成 sitemap/robots；提供公开后端时，`build:prerender:data` 可按区域生成门店、点评、帖子、榜单、活动、圈子和话题详情快照，常驻 SSR 与目标环境自动接入仍未完成
  - `admin-web`: 管理员登录、控制台概览、门店管理、基础数据 `/data/meta`、订单退款 `/data/orders`、点评审核 `/audit/reviews`、达人认证 `/audit/expert-certifications`、商户点评申诉 `/audit/review-appeals`、帖子审核 `/audit/posts`、审计日志 `/system/audit-logs`、隐私任务 `/system/privacy-tasks`、种子导入和 `CN / EU` 区域切换
- 管理端种子导入失败明细已完成真实本地文件输出:`errorFile` 指向 `local-storage/import-errors/*.json`。

### 1.3 认证安全补充能力

- `POST /auth/send-code` 验证码限流已完成:按 `scene + account`、`deviceId`、`IP` 三层返回 `429 + Retry-After`。
- 当前默认走本地内存版,只覆盖 `send-code` 接口;配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis,不用改当前数据库导入脚本。
- `Idempotency-Key` 重复提交保护已完成:写请求带同 key + 同请求体会复用首个响应,同 key + 不同请求体返回 `409`;默认本地内存,配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis,`web` 通用写请求会自动带 key。

### 1.4 隐私中心当前闭环

- 后端已完成隐私概览、数据导出任务、ZIP 下载、删除申请、冷静期撤销和到期匿名化。
- 当前真实可导出 `account`、`reviews`、`orders`、`reservations`、`favorites`、`posts`、`follows`、`messages`、`circles`、`topics`。
- `web` 与 Flutter 隐私中心均支持创建导出、带登录态下载、验证码/密码校验删除和冷静期撤销，并已接入协议接受留痕、设备登记/列表、Push token 脱敏状态和主动停用设备。
- 后端自动化已覆盖导出 ZIP 内容、下载、删除撤销、冷静期到期处理、注销到期后的设备停用与登录阻断；Playwright 真实后端 E2E 已覆盖创建导出、下载、创建删除申请和撤销。
- `topics` 导出包含话题 `id/name/region/followedAt`；注销删除本人话题关注并按真实行数刷新 `follower_count`，帖子话题关联与热榜快照保持不动。

### 1.5 M7 帖子内容第一阶段

- 后端已完成帖子、图片、话题关联、点赞、转发、评论、举报数据模型；发帖后进入 `audit_task.biz_type=4`，作者可查看待审/驳回原因并编辑重提，审核通过后才进入公开列表与详情。
- 帖子支持作者删除、点赞切换、转发/取消转发、评论、举报和 `user_favorite.target_type=2` 收藏；注销到期会匿名化帖子、帖子评论和举报，未审核帖子不会继续公开。
- 帖子正文在审核通过时解析合法 `@昵称` 并发送独立 `social.mention` 通知；帖子评论创建时即时解析 `@昵称`，同一条内容内同一用户只提醒一次，跳过自己、不存在用户和重名用户，通知沿用现有 WebSocket/REST 聚合链路。
- Flutter 已完成社区流、帖子详情、发帖/编辑、图片上传、话题、点赞、评论、转发/取消转发和举报；PC Web 仅提供 `/community` 与帖子详情只读展示及 APP 引导。
- 管理端 `/audit/posts` 支持按区域查询 `bizType=4` 任务并通过/驳回；隐私 ZIP 的 `posts.json` 导出本人真实帖子。
- 真实 FCM/APNs 推送仍未实现；帖子转发、关注流、私信、官方圈子和话题广场/热榜已实现。

### 1.5.1 M7 话题广场、7 天热榜与治理

- C 端已完成推荐、最新、热榜、已关注、详情、话题帖子、关注/取消关注接口；所有数据按 `X-Region` 隔离，关注写操作和“已关注”列表要求登录。
- 发帖时话题不存在会同区域自动建档；屏蔽名称拒绝，已合并名称解析到最终目标；审核、编辑、删除会按真实公开帖子关系刷新 `post_count`。
- 热榜公式为 `post_count_7d * 20 + like_count_7d * 3 + comment_count_7d * 5 + (recommended ? 100 : 0)`；置顶优先，普通项按分数、关注数、ID 排序。
- `topic_hot_snapshot` 每小时按 CN/EU 独立增量重算，首次读取无快照时同步兜底，事务替换失败保留旧快照；热榜不依赖 Redis。
- 管理端 `/operations/topics` 支持筛选、改名、推荐、`pinnedSort`、屏蔽/恢复、手动重算和不可逆合并。合并会去重迁移帖子/关注关系并按真实行数重算计数。
- Flutter 提供推荐/热榜/已关注三 Tab、详情帖子和关注乐观更新；PC Web `/topics`、`/topics/:id` 完全只读，不提供关注、创建或发帖按钮。
- 当前没有独立话题 Feed；帖子审核通过后会给关联话题关注者发送 `topic.update` 站内通知（跳过作者本人、同帖多话题去重，跳转帖子详情）。

### 1.5 M4 团购交易与预订闭环

- 团购交易已完成：门店团购列表/详情、下单、有限库存原子扣减、未支付取消恢复库存、模拟支付、SHA-256 回调验签与幂等、按购买数量发券、订单/券列表、退款申请和已核销券退款拦截；退款不再由用户请求同步完成，而是进入商户审核。
- 区域支付默认通道已隔离：`CN=alipay_mock`、`EU=stripe_mock`;真实 Stripe/支付宝 SDK 尚未接入，继续归 M6/上线集成范围，不能把 mock 写成真实收款。
- 预订已完成：时段容量、自动/人工确认、创建、列表、详情、取消截止时间、改期重新确认、容量释放和变更时间线。
- 商户履约后端已完成：确认、拒绝、到店、爽约、券码核销；SQL 同时约束商户归属、区域、当前状态和券有效期，避免串店操作。
- Web 已完成团购详情、订单、券、在线预订、我的预订和预订详情页面；独立 `merchant-web` 已补齐注册、登录、资质提交/状态分流、概览、门店、员工、预订、团购、订单退款、点评回复/申诉页面。

### 1.6 M5a/M5b1/M5b2/M5b3/M5b4 商户身份与经营后端

- M5a 身份与权限后端已完成：`merchant_operator`、`merchant_role`、操作者角色/门店关联、资质申请和商户操作日志已同步 H2/MySQL；登录不再依赖单个配置账号。
- 商户注册后可提交资质，管理员可按区域查看并通过/驳回；待审核账号只能补资料，不能进入经营工作台。
- 主账号可创建、查询、编辑、启停员工；角色权限与门店范围来自数据库，跨商户门店授权被拦截，停用 `merchant_operator` 会让其已有 B 端 token 失效。
- M5a 前端闭环已完成：`merchant-web` 已接注册、资质状态/驳回重提、审核状态登录分流和员工角色/门店范围管理；`admin-web` 已接商户资质审核列表、通过与带原因驳回。真实浏览器已验证已审核商户进入工作台、过期会话回登录页、员工弹层和管理端 EU 审核操作。
- 预订工作台已完成 `GET /api/b/v1/reservations` 分页筛选、详情时间线和 `POST /api/b/v1/reservations/:id/reschedule` 商户改期；改期按原门店/区域校验并以“先占新时段、成功后释放旧时段”保证容量一致。
- 预订确认/拒绝/改期/到店/爽约和券核销已接数据库权限点及员工门店范围，履约日志和券核销人记录实际 `merchant_operator.id`，不再拿 `merchant_id` 糊弄操作人。
- 经营看板已完成 `GET /api/b/v1/dashboard`，按最多 90 天范围聚合真实浏览量、支付订单/金额、核销券、预订状态、评分和点评数；公开门店详情访问按日累加 `shop_view_daily`。
- 商户团购已完成 `GET/POST /api/b/v1/deals`、`PUT /api/b/v1/deals/:id` 和 `PUT /api/b/v1/deals/:id/status`：创建/编辑固定回到待审下架，管理端通过统一审核任务审核，通过后仍由商户主动上架。
- 商户订单与退款已完成 `GET /api/b/v1/orders` 和 `POST /api/b/v1/orders/:id/refund-audit`：按商户、区域和员工门店范围隔离；退款通过会在一个事务内更新退款、订单、券和团购库存，驳回不改变订单与券状态，操作日志记录实际员工 ID。
- 商户门店完整草稿已完成：支持新门店空草稿、从线上门店复制修改草稿、基础资料/相册/菜单完整快照保存、`biz_type=5` 提交审核、审核通过整体应用、驳回重提和 `base_updated_at` 版本冲突保护；审核前公开线上数据不变化。
- 门店修改审核只覆盖商户可编辑字段，评分、点评数、`has_deal`、商户归属和区域保持原值；照片和菜品按完整候选快照整体替换，事务提交后再同步搜索索引。
- 商户点评经营后端已完成：`GET /api/b/v1/reviews` 按商户、区域和员工门店范围查询公开点评；`PUT /api/b/v1/reviews/:id/reply` 支持创建/覆盖商家回复，C 端点评列表和详情返回 `merchantReply`。
- 商户点评申诉已完成：申诉草稿、保存、提交会生成 `audit_task.biz_type=6`；管理端审核通过会隐藏点评、重算门店评分并保留商家回复记录不再公开暴露，审核驳回后商户可修改理由和证据重提；用户编辑/删除点评会失效旧申诉和待审任务。

### 1.6.1 管理端数据库 RBAC 基础

- 管理员身份不再依赖配置账号：`admin_user`、`admin_role`、`admin_permission`、`admin_user_role`、`admin_role_permission` 与 `admin_region_scope` 已同步 H2/MySQL，并为 `admin` 种子账号配置内置角色、权限和 `CN/EU` 范围。
- `POST /api/admin/v1/auth/login` 使用数据库账号与 BCrypt；`GET /api/admin/v1/auth/me` 返回当前身份、权限和区域范围。token 仅缓存身份标识与过期时间，每次管理端请求都会重新加载启用账号、角色、权限与区域：角色停用后旧 token 仍可取得 `200` 的 `auth/me`，但权限被实时收回，固定受限 API 返回 `403`，动态审核列表可返回 `200` 空结果；管理员账号停用后旧 token 才会在下一次请求返回 `401`，前端清理本地会话并回登录页。
- `GET /api/admin/v1/menus` 按权限过滤菜单；所有非登录、退出、身份和菜单的管理端业务接口均要求权限元数据。受限账号访问无权限 API 或越出 `admin_region_scope` 的 `X-Region` 时返回 `403`。
- 管理员与角色权限接口已完成：`/api/admin/v1/rbac/permissions`、`/api/admin/v1/rbac/roles`、`/api/admin/v1/rbac/admins`。`admin-web` 已提供 `/system/admins`、`/system/roles`，路由和菜单使用相同权限码。

### 1.7 M6 Flutter 本地业务闭环

- Flutter 已完成 EU/CN 区域与简繁英语言切换、认证会话恢复、邮箱/手机号注册登录、密码重置、封禁账号免登录申诉与进度查询、资料/账号绑定/改密码和设备生命周期登记；通知中心支持未读筛选、下拉/空状态刷新、失败重试和历史通知分页加载，隐私中心支持导出任务历史分页。
- 浏览侧已完成首页、搜索（热词 + 登录用户搜索历史面板 + 输入联想 + 门店结果历史分页，支持清空/单条删除）、门店详情（含门店收藏/取消收藏、公开点评预览与相似门店推荐）、独立门店点评列表（排序、评分和带图筛选，筛选请求防乱序覆盖，后续页按点评 ID 去重）、城市榜单列表/详情、运营活动列表/详情、团购下单与在线预订；未配置 Google Maps、真实支付渠道时明确展示不可用原因，不把占位能力写成已接通。
- 首页在 `CN / EU` 区域或浏览仓储变化时会自动重新加载推荐门店，避免区域标题更新后继续展示旧区域列表。
- 独立门店点评列表首次加载失败可重试，重试保留当前排序和筛选条件。
- 点评侧已完成新建、本人详情回填编辑、四维评分、消费金额、标签、系统相册选图、评论区历史分页与楼中楼回复，以及带鉴权/区域/语言/幂等键的 multipart 图片上传。
- 点评编辑器会明确反馈选图、上传和保存失败，失败后保留表单并恢复操作按钮；异步入口会拦截重复上传和重复提交。
- 我的券列表支持状态筛选和历史分页，首次加载失败可重试；切换状态会失效旧筛选的分页请求，避免旧券混入当前结果。
- 券详情携带列表预载数据时会在完整详情失败后保留基础券码，并提供局部重试以恢复使用规则、核销状态和提示。
- 我的预订列表支持状态筛选和历史分页，首次加载失败可重试；切换状态会失效旧筛选的分页请求，避免旧预订混入当前结果。
- 用户中心资料请求按页面生命周期稳定持有，首次加载失败可重试，不会因父级重建隐式重复请求。
- 本地达人认证状态首次加载失败可重试；页面退出后的迟到响应不会再写入已释放的申请理由控制器。
- 账户设置资料首次加载失败可重试，页面销毁后的迟到响应不会写入已释放的表单控制器。
- 隐私中心聚合数据首次加载失败可重试，重试会重新获取隐私规则、导出任务、协议记录和设备列表。
- 门店团购列表首次加载失败可重试，未配置真实支付渠道时仍明确阻断支付并保留已创建订单。
- 城市榜单详情首次加载失败可重试，列表原有首次重试和刷新失败保留数据行为保持不变。
- 运营活动详情首次加载失败可重试，列表原有首次重试和刷新失败保留数据行为保持不变。
- 点评详情首次加载失败可重试并恢复评论，重复详情请求按最新一次结果更新，避免迟到响应覆盖当前状态。
- 帖子详情首次加载失败可重试，重试会同步重新获取主帖和第一页评论并清理旧回复状态。
- 帖子详情点赞和评论失败会明确提示并恢复操作按钮；评论失败保留输入内容和回复目标，动作入口会拦截并发重复提交。
- 帖子详情评论区第一页失败会显示原因并可局部重试，重试不会重复请求已成功加载的主帖。
- 帖子举报失败会保留已填写理由并恢复举报入口，重新打开可直接重试；成功后才清空举报草稿。
- 点评举报失败同样保留已填写理由并恢复入口，重新打开可直接重试；成功后才清空举报草稿。
- 帖子点赞和转发成功后直接使用动作响应更新计数与状态，不再追加一次可能让整页退化的主帖刷新请求。
- 帖子评论成功后本地递增主帖评论数，仅重拉需要重组楼层的评论区，不再重复获取主帖详情。
- 公开用户主页和粉丝/关注列表首次加载失败均可重试；关系重试回到第一页并清理旧分页加载态。
- 我的点评、我的帖子和收藏集合首次加载失败可重试；重试第一页会失效仍在返回的旧分页请求。
- 券码详情直接路由首次加载失败可重试；从列表进入且有预载券数据时仍可降级展示基础信息。
- 社区推荐/关注流当前标签首次加载失败可重试；两条流独立持有请求版本，重试不会清空另一标签缓存。
- 话题广场推荐、热榜、已关注标签首次加载失败可重试；三标签独立持有请求版本和分页状态。
- 话题详情公开帖子第一页失败可重试并失效旧分页，话题当前关注状态保持不变。
- 门店详情主请求失败会显示原因并可安全重试，不再从 `setState` 回调返回 Future 触发框架异常。
- 同城圈子广场、圈子详情公开帖子和成员列表首次失败均可重试；重试第一页会失效各自旧分页请求。
- 在线预订可用时段首次加载失败可按当前门店、日期和人数重试，并清除可能已失效的时段选择。
- 预订详情改期失败会保留已查询和选中的可用时段，恢复按钮后可直接重试；只有改期成功才清理候选时段。
- 订单退款申请失败会保留已填写原因，重新打开对话框可直接重试；只有退款申请成功才清空草稿。
- 订单支付、取消和退款动作在方法入口拦截并发重复请求，不依赖按钮下一帧重建才生效。
- 预订详情的时段查询、取消和改期动作同样在方法入口拦截并发重复请求。
- 点评评论区第一页失败可独立重试；立即失败由页面接管，重试会失效旧评论分页并清理回复目标。
- 门店详情的点评预览与相似门店失败可各自局部重试，不重复请求主详情或影响收藏状态。
- 搜索发现面板真实失败会显示并可重试；搜索结果可按当前关键词重试，旧关键词分页不会回写新结果。
- 用户中心已完成我的点评、收藏（门店/帖子可跳转详情）、订单、券、预订、浏览足迹、成长值流水、账户设置（资料/绑定账号/改密码）、本地达人认证申请/重提、公开主页达人标识及粉丝/关注历史分页：我的点评、我的帖子和收藏支持历史分页；订单列表支持支付状态筛选和历史分页，首次失败可重试，筛选切换会失效旧分页请求，订单详情支持支付/取消/退款申请、退款进度与结果横幅展示；支付成功会发 `order.paid` 站内通知并跳转订单详情（重复回调幂等）；商户或平台审核退款后会发 `order.refund.result` 站内通知并跳转订单详情；我的券支持状态筛选和历史分页，列表读取时会顺带把过期待使用券落成 `status=3`，并从通知 `code` 参数高亮定位；`GET /coupons/:code` 券码详情返回规则、`usable` 与核销二维码，PC Web `/user/coupons/:code` 已接列表/订单入口；券码到期前 3 天 / 1 天会发 `coupon.reminder`，过期后发 `coupon.expired`；我的预订支持状态筛选和历史分页，创建预订会发 `reservation.created`（自动确认/待确认），预订详情支持取消、查询新时段、改期和时间线；浏览足迹支持历史分页、下拉刷新、单条删除和清空。
- M7 帖子第一阶段已接入 Flutter：首页社区入口、推荐流/关注流历史分页、详情、发帖/编辑、图片上传、话题广场推荐/热榜/已关注历史分页、话题详情公开帖子分页、同城圈子广场/成员/圈内公开帖子历史分页、点赞、评论区历史分页与楼中楼回复、转发/取消转发、举报和“我的帖子”均使用真实 API。
- 本人帖子编辑数据加载失败时会阻断空表单提交与删除，展示错误并允许重试，完整数据恢复后才开放编辑动作。
- 帖子图片上传与创建/更新失败会展示原因、复位操作状态并保留表单内容，避免异常冒泡或要求用户重新填写。
- 本轮已补社区转发/详情动作、圈子/话题帖子跳转、首页订单入口和消息刷新相关 Flutter 聚焦测试，见 `app/test/features/community/*`、`circle_screens_test.dart`、`topic_screens_test.dart`、`home_screen_test.dart` 与 `message_screens_test.dart`。
- Flutter 城市榜单列表已补首次加载重试与刷新失败保留现有榜单，详情跳转行为不变。
- Flutter 运营活动列表已补首次加载重试与刷新失败保留现有活动，详情跳转行为不变。
- Flutter 成长值/积分流水已补后续页 ID 去重与刷新失败保留已有流水。

### 1.8 还没做完的别硬吹

- M1-M7 当前文档已声明的帖子、转发、关注流、1v1 私信、官方圈子、话题热榜、评论盖楼、帖子正文/评论 `@提醒`、本地达人认证和认证商户号闭环均已完成，M5a 商户注册/资质/员工与管理端商户审核前台、管理端数据库 RBAC，以及分类/城市/商圈基础数据治理、Banner 配置、搜索热词配置和运营活动配置均已收口；C 端公开运营活动列表/详情与首页透出也已落地。管理端 C 端用户治理（用户查询/详情/封禁/解封，封禁即时吊销登录态并写审计日志）已于 `2026-07-24` 落地；用户封禁申诉链路（被封禁用户免登录提交/查询申诉、`biz_type=8` 管理端审核、通过自动解封、直接解封自动了结待审申诉、Web 与 Flutter 登录入口）已补齐；管理端订单平台退款仲裁（`POST /orders/:id/refund-audit` + `data:order:write`）、超时未支付关单与支付流水补偿（定时任务 + `POST /orders/reconcile`）也已于 `2026-07-24` 落地；PC SEO 已完成静态入口和可选真实 API 数据快照预渲染，常驻 SSR、完整国际化和真实第三方适配仍未完成；门店相似推荐与公开页客户端运行时 metadata 已完成，真实环境凭证联调仍未完成。

- 真实 `MySQL` 导库 + 默认配置启动冒烟已补 `scripts/ci/mysql-smoke.ps1` 和 GitHub Actions 入口,并已于 `2026-07-12` 用临时 `MySQL 8` 实例 (`127.0.0.1:13306`) 在当前机器实跑通过；宿主机 `MySQL80` 的现成 root 凭证仍不可用，但这已经不是仓库侧阻塞。
- `Redis` 状态存储和 `S3` 兼容对象存储代码入口已接入:验证码限流、`Idempotency-Key` 幂等缓存可通过 `APP_STATE_STORE_PROVIDER=redis` 切 Redis,文件上传可通过 `APP_FILE_STORAGE_PROVIDER=s3` 切 S3。仓库内 Playwright 浏览器冒烟已补,`scripts/ci/browser-smoke.ps1` 会直接托管 `web` / `admin-web` 的 Vite 进程并运行 `web/e2e/browser-smoke.spec.ts`,GitHub Actions 已纳入 `-IncludeBrowserSmoke`;真实后端关键链路 E2E 已补 `scripts/ci/browser-e2e.ps1`,并已覆盖真实图片上传、成长值流水页、手机号绑定、改密码后重新登录、后台成功导入以及游客点赞 / 评论 / 举报登录后自动续执行;`scripts/ci/storage-smoke.ps1` 已补 S3 兼容对象存储真上传冒烟并纳入 `-IncludeStorageSmoke`;`.github/workflows/release.yml` / `rollback.yml` 和 `package-release.ps1`、`deploy-release.ps1`、`rollback-release.ps1` 已补最小发布 / 回滚自动化。还没完成的是带真实 MySQL / Redis / S3 / SSH 凭证的环境联调与发布回滚演练。

## 2. 这些状态已经标在哪些文档里

| 文档 | 你该看什么 |
|---|---|
| `README.md` | 仓库级当前实现状态、启动方式、MySQL 导入命令、演示账号 |
| `docs/README.md` | 文档总览、当前代码状态、文档阅读顺序 |
| `docs/需求文档.md` | 当前代码已落地范围总览 |
| `docs/M1-M2实施计划与验收清单.md` | 最准确的完成/未完成勾选清单 |
| `docs/接口设计.md` | 当前已实现 API 清单和目标态接口边界 |
| `docs/数据库设计.md` | 当前真实落库表、MySQL 脚本口径、演示账号说明 |
| `docs/测试清单与验收用例.md` | 已完成自动化验证和仍待验证项 |

别只盯一份文档。总览看 `README.md`，真要判断有没有做完，以 `docs/M1-M2实施计划与验收清单.md` 为准。

### 2.1 功能 / 文档 / SQL 对照表

| 功能 | 当前状态 | 已标注文档 | 对应 SQL / 说明 | 导入后可直接演示 |
|---|---|---|---|---|
| `M1` C 端浏览链路 | 已完成 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `category/city/area/merchant/shop/shop_photo/dish/home_banner/home_feed`；`02_seed_data.sql` 预置城市、分类、门店、Banner、Feed | 首页、列表、详情、城市/分类/商圈筛选、`CN/EU` 区域切换 |
| 头部关键词搜索 / 联想 / 热词 / 搜索历史 | 已完成 MySQL 默认 + Elasticsearch 可切换链路 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `/search/shops` 支持 MySQL/ES provider；ES 已覆盖分词、拼音、纠错、筛选、距离排序、索引重建/增量同步与真实 smoke；热词优先读 `hot_keyword`，空表/全停用时回退当前 MySQL 统计；联想/历史仍复用当前 MySQL 数据；`search_history` 每用户每区域最多 20 条，写入后按最近使用裁剪；支持整区清空与单条删除 | 首页头部输入“火”展示联想并进入结果页；公开端热词默认展示运营配置，删空后回退统计结果；登录用户可查看/清空当前区域历史，也可删除单条，超额旧词自动淘汰；ES smoke 验证拼音、纠错与距离排序 |
| 管理端门店管理 / 种子导入 | 已完成 | `README.md`、`docs/README.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `merchant/shop/import_batch`；`02_seed_data.sql` 预置门店与商户演示数据；`import_batch` 导入后默认留空,要实际导一次才有批次记录 | 管理员登录后看门店列表、编辑门店、导入种子数据 |
| 管理端分类 / 城市 / 商圈治理 | 已完成（本地口径） | `README.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/权限矩阵.md`、`docs/测试清单与验收用例.md` | `category/city/area` 使用自增 ID、`status`、区域唯一约束和读取索引；`02_seed_data.sql` 预置 `data:geo:read/write` 并授予 `data_operator` | `/data/meta` 三页签 CRUD/启停/删除；C 端隐藏停用项；写入、审核和榜单发布窗口重新校验启用引用 |
| `B` 端最小只读工作台 | 已完成最小骨架 | `README.md`、`docs/README.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/测试清单与验收用例.md` | 复用 `merchant/shop` 与现有浏览查询;一期商户账号绑定单区域,`X-Region` 与经营区域不一致直接 `401`;暂不新增 B 端员工 / 角色表 | `GET /api/b/v1/health`、`GET /api/b/v1/account/me`、`GET /api/b/v1/roles`、`GET /api/b/v1/shops` |
| M5b3 门店完整草稿审核 | 已完成后端闭环 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `merchant_shop_change/merchant_shop_change_photo/merchant_shop_change_dish`，并使 `shop_photo.id/dish.id` 自增；运行时提交产生 `audit_task.biz_type=5` | 创建/修改草稿、相册/菜单快照、提交审核、通过整体应用、驳回重提、版本冲突拦截 |
| M5b4 商户点评经营 | 已完成后端闭环 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `review_merchant_reply/merchant_review_appeal`；运行时提交申诉产生 `audit_task.biz_type=6` | 商户点评列表、回复公开展示、申诉提交、管理端通过/驳回、驳回后重提、用户编辑/删除点评失效旧申诉 |
| 认证最小闭环 | 已完成 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `app_user/verification_code/user_session`；`02_seed_data.sql` 预置两个可密码登录的 `app_user`；`verification_code`、`user_session` 导入后默认留空,运行时生成 | 密码登录、资料页、我的点评；验证码发送 / 注册 / refresh 需要运行接口后才会产生日志数据 |
| 验证码发送限流 | 已完成当前本地版 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/测试清单与验收用例.md` | 当前**无新增 SQL**；`send-code` 限流先走本地内存计数,现有导库脚本不用额外改表 | 重复发送验证码时触发 `429 + Retry-After` |
| `Idempotency-Key` 重复提交保护 | 已完成当前基础版 | `README.md`、`docs/README.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/测试清单与验收用例.md` | 当前**无新增 SQL**；幂等结果默认走本地内存缓存,配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis;MySQL 审计表仍是目标态增强 | 同 key + 同请求体复用首个响应,同 key + 不同请求体返回 `409` |
| 用户中心基础能力 | 已完成当前 `M2` 范围 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/测试清单与验收用例.md` | 直接复用 `app_user/verification_code/review/review_image`；`02_seed_data.sql` 已预置演示账号、我的点评、驳回案例 | 我的资料、账号绑定、改密码、成长值流水、我的点评、我的点评详情、公开用户主页最小版、驳回原因回显 |
| M7 本地达人认证 | 已完成 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/业务流程与状态机.md`、`docs/权限矩阵.md`、`docs/术语与枚举规范.md` | `01_schema.sql` 建 `user_expert_certification`；`02_seed_data.sql` 预置 `audit:expert_certification:read/write` 并授予 `content_auditor`；运行时提交产生 `audit_task.biz_type=7` | 资料页提交 / 驳回后重提、管理端 `/audit/expert-certifications` 通过 / 驳回、公开主页 / 点评 / 帖子作者达人标展示 |
| 管理端审计日志查询 | 已完成 | `README.md`、`docs/README.md`、`docs/接口设计.md`、`docs/权限矩阵.md` | 复用现有 `audit_log`；`02_seed_data.sql` 预置 `system:audit_log:read`；运行时登录、RBAC 和审核动作持续写日志 | 管理端 `/system/audit-logs` 支持按 `adminId/action/target/keyword` 分页筛选审计日志 |
| 管理端隐私任务查询 | 已完成 | `README.md`、`docs/README.md`、`docs/接口设计.md`、`docs/权限矩阵.md` | 复用现有 `privacy_export_task/privacy_delete_task`；`02_seed_data.sql` 预置 `system:privacy_task:read`；运行时统一查询导出/删除任务 | 管理端 `/system/privacy-tasks` 支持按 `userId/taskType/status/keyword` 分页筛选隐私导出和账号删除任务 |
| 管理端订单/退款/对账查询与处置 | 已完成 | `README.md`、`docs/README.md`、`docs/接口设计.md`、`docs/权限矩阵.md`、`docs/业务流程与状态机.md` | 复用现有 `order/payment/refund`；`02_seed_data.sql` 预置 `data:order:read/write` 并授予 `data_operator`；运行时按区域查询订单、支付流水和退款记录，支持平台退款仲裁与对账补偿 | 管理端 `/data/orders` 支持筛选、退款仲裁、手动对账补偿；定时任务关闭超时未支付订单并标记失败支付流水 |
| 管理端 Banner 配置 | 已完成 | `README.md`、`docs/接口设计.md`、`docs/权限矩阵.md` | 复用现有 `home_banner`；`02_seed_data.sql` 预置 `operations:banner:read/write` 并授予 `operations_manager`；运行时按区域和可用城市校验写入 | 管理端 `/operations/banners` 支持按城市查看当前首页口径、新建/编辑/启停/删除 Banner，并即时联动 C 端 `/home/banners` |
| 管理端搜索热词配置 | 已完成 | `README.md`、`docs/接口设计.md`、`docs/权限矩阵.md` | `01_schema.sql` / `schema.sql` 已建 `hot_keyword`；`02_seed_data.sql` 预置 `operations:hotword:read/write` 并授予 `operations_manager`；运行时按区域维护启停和排序 | 管理端 `/operations/hotwords` 支持新建/编辑/启停/删除热词，并即时联动 C 端 `/search/hot`；删空后自动回退统计结果 |
| 轻积分 / 等级 | 已完成当前范围 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `growth_points_log/growth_rule/level_config` 支撑发点评、获赞、带图点评、完成订单四类触发；每类按业务 ID 幂等写成长值/积分两条流水并更新用户等级 | 触发对应行为后可在 `/user/growth-records` 查看流水；管理端可维护规则与等级；重复支付回调或重复点赞不会重复奖励 |
| 点评发布 / 互动 / 审核 | 已完成 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `review/review_image/review_like/review_comment/review_report/audit_task`；`02_seed_data.sql` 预置公开点评、点评图片、点赞、评论、待审 / 驳回审核任务；`review_report` 表会建好,但默认不塞演示举报记录,免得你第一次点举报就撞重复 | 写点评、编辑点评、删除点评、点评详情、点赞 / 评论 / 举报、管理端审核 |
| 本地图片上传 | 已完成 | `README.md`、`docs/需求文档.md`、`docs/M1-M2实施计划与验收清单.md`、`docs/接口设计.md`、`docs/测试清单与验收用例.md` | 这块不靠额外导库表跑上传文件本身；上传文件落 `backend/local-storage/uploads`；点评提交后图片 URL 仍落到 `review_image` | 写点评 / 编辑点评时选本地图片上传并预览 |
| 隐私中心 | 已完成当前可用闭环 | `README.md`、`docs/README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `01_schema.sql` 建 `privacy_export_task/privacy_delete_task`;导出文件运行时落 `backend/local-storage/privacy-exports` | 创建数据导出、认证下载 ZIP、提交账号删除、冷静期内撤销 |
| M7 帖子内容闭环 | 已完成第一阶段 | `README.md`、`docs/需求文档.md`、`docs/接口设计.md` | `01_schema.sql` 建 `post/post_image/topic/post_topic/post_like/post_repost/post_comment/post_report`；审核复用 `audit_task.biz_type=4` | Flutter 点赞、评论、转发/取消转发、帖子正文/评论 `@提醒` 等互动，PC 只读，管理端审核、帖子隐私导出；不含关注/私信/圈子/真实推送 |
| M7 关注关系与关注流 | 已完成 | `README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md` | `01_schema.sql` 建 `user_follow`，`user_notification` 增加 `actor_user_id`；关注通知使用 `GLOBAL` | 关注/取关、粉丝/关注列表、区域关注流、Flutter 双流与公开主页、PC 只读关系、`follows` 隐私导出；不含私信/圈子/真实推送 |
| M7 APP 私信 | 已完成 | `README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md` | `conversation/message/user_block/message_report` | 1v1 文本（发送中显示进度，失败保留草稿并可直接重试）、会话列表分页（首次失败可重试、刷新失败保留列表）、消息历史向前分页（首次加载失败可重试且不误确认已读；已读同步失败仍保留已加载历史并明确提示），以及 Flutter 分页黑名单管理与解除拉黑（首次失败可重试、刷新失败保留名单；会话举报/拉黑进行中禁止重复提交）；列表保留分页元数据并按 ID 去重，另含举报、WebSocket、`messages` 导出与注销治理；PC Web 无入口 |
| M7 官方圈子 | 已完成 | `README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md` | `circle/circle_member`，`post.circle_id` | 区域官方圈子、加入退出、成员发帖、管理端维护、Flutter 完整互动、PC 只读、`circles` 隐私治理 |
| M7 话题广场与热榜 | 已完成 | `README.md`、`docs/需求文档.md`、`docs/接口设计.md`、`docs/数据库设计.md`、`docs/测试清单与验收用例.md` | `topic/post_topic/topic_follow/topic_hot_snapshot` | Flutter 可关注，PC Web 只读，管理端治理/不可逆合并，数据库 7 天热榜，`topics` 隐私导出与注销治理 |

## 2.2 全局功能完成矩阵

> 状态含义：`已完成` 表示实现、自动化和当前本地运行证据齐全；`部分完成` 表示已有主链路但仍有明确需求缺口；`外部待验收` 表示仓库入口已具备但缺少真实账号、凭证或目标环境结果。

| 功能域 | 状态 | 已完成证据 | 剩余工作 | 完成判定 |
|---|---|---|---|---|
| M1-M4 用户核心链路 | 已完成（本地口径） | 浏览（Flutter 足迹分页且加载/刷新失败可恢复）、搜索（Flutter 搜索历史保留分页元数据并可加载更多）、认证（Flutter 账户设置已接资料保存、账号绑定与密码更新）、点评、成长、榜单、收藏、交易和预订均有后端、Web 与自动化覆盖；支付成功会发 `order.paid`（回调幂等、PC/Flutter 可跳转订单详情）；预订创建会发 `reservation.created`（自动确认/待确认）；预订到店前 2 小时 / 30 分钟站内提醒已落地（`reservation.reminder` + 时间线 action_type=9）；商户确认/拒绝/到店/爽约会发 `reservation.status` 站内通知并联调 PC 预订详情横幅；券码到期前 3 天 / 1 天提醒与过期自动标记已落地（`coupon.reminder` / `coupon.expired` + `remind_status` 去重，PC Web 我的券页支持 status/code 定位）；券码详情 `GET /coupons/:code` 与 PC 二维码详情页已落地；商户核销成功会发 `coupon.verified` 并联调 PC 券码详情；退款审核结果通知 `order.refund.result` 与订单详情取消/退款闭环已落地；点评审核通过/驳回会发 `review.audit.result` 并联调 PC 我的点评详情横幅；商户点评申诉通过后会隐藏点评并通知作者 `review.hidden`；点评获赞/新评论会发 `review.like` / `review.comment`，评论盖楼回复会额外通知被回复者 `review.comment.reply`（被回复者即点评作者时不重复）；达人认证审核通过/驳回会发 `expert.certification.result` 并联调 PC 资料页横幅；帖子审核通过/驳回会发 `post.audit.result` 并联调 PC 帖子详情横幅与 Flutter 消息跳转；帖子评论盖楼回复会额外通知被回复者 `post.comment.reply`（被回复者即帖子作者时不重复） | 真实支付归第三方阶段 | 当前自动化、浏览器 E2E 和临时 MySQL 8 smoke 有通过记录；目标环境仍待验收 |
| M5 商户经营后端 | 已完成 | 入驻、员工 RBAC、门店范围、预订、团购、订单退款、门店草稿、点评回复申诉已落地 | 无后端主流程缺口 | 后端权限、状态机、跨商户和跨区域测试通过 |
| 商户端与管理端完整闭环 | 部分完成 | `merchant-web` 已有注册、登录、资质、看板（含待办与快捷入口）、门店草稿编辑/提交审核/驳回原因回显、员工、预订（确认/拒绝/到店/爽约）、预订时段配置、团购创建/编辑/上下架/驳回原因回显、退款、券码核销和点评页面；管理端已有数据库 RBAC、控制台经营/审核概览与快捷入口、Banner、搜索热词、运营活动、分类/城市/商圈、订单退款查询/平台仲裁/对账补偿、商户资质/点评/申诉/帖子/门店草稿/团购审核、门店、榜单、成长、圈子和话题治理，审计日志、隐私任务查询，以及 C 端用户治理（查询/详情/封禁/解封，封禁即时吊销登录态、拦截密码与验证码登录并写审计日志）和用户封禁申诉闭环（免登录提交/查询申诉、`/audit/user-appeals` 审核页、通过自动解封、直接解封自动了结待审申诉、Web 登录弹层申诉入口）；内容举报聚合治理（`/audit/reports`，点评/帖子/私信举报列表与 dismiss/hide 处理） | 真实支付渠道原路退款未接 | 已完成的 B/Admin 页面、权限、区域范围、角色实时收权、账号停用 `401`、审计日志/隐私任务/订单退款查询与仲裁补偿、基础数据、用户治理和封禁申诉真实后端 E2E 通过；其余经营深度与第三方集成另行验收 |
| PC Web 产品缺口 | 部分完成 | 首页、列表、详情、搜索、交易、预订、用户中心和社区只读页已落地；商户高级筛选、真实分页、点评排序/评分/带图筛选、分享、门店相似推荐、公开页客户端运行时 metadata、登录用户门店浏览足迹（每用户每区域最多 50 条）、C 端运营活动公开列表/详情与首页透出、消息中心页（列表/分页/全部已读），券码通知定位，以及 7 个静态公开入口和可选真实 API 详情快照预渲染、构建清单、sitemap/robots 已接入 | 常驻 SSR 服务、按 CN/EU 自动发布快照、真实域名缓存与部署验收 | 组件测试、后端查询测试、预渲染/快照脚本测试和本地 H2 快照构建已有证据；目标环境自动化尚未验收 |
| 社区与消息尾项 | 部分完成 | 帖子、评论盖楼、帖子正文/评论 `@提醒`、本地达人认证、认证商户号、转发、关注流、私信、圈子、话题和通知聚合已落地；Flutter 通知中心支持分页、未读筛选及刷新失败保留数据；敏感词库管理 + 点评/帖子/评论/私信写入拦截已落地（`operations:sensitive_word:*`） | 真实移动推送、第三方机审 | 自动化覆盖已落地的社交关系、达人/认证商户审核与公开 badge、通知去重、`@提醒` 分发、隐私治理、敏感词拦截和 Flutter 转发/互动链路；尾项仍待实现 |
| Flutter 与真实第三方 | 部分完成 | Flutter 具备区域切换、基础三语言入口、交易/社区/隐私主链路；未配置能力会诚实禁用 | 完整 i18n、点评翻译、Google Maps、Stripe/PayPal/支付宝/微信、FCM/APNs、邮件短信和内容审核 | 仅有仓库内 mock/契约与未配置阻断验证；真实 sandbox、凭证和供应商联调仍待验收 |
| 目标环境与上线执行 | 外部待验收 | MySQL、Redis、S3、ES、发布回滚脚本及 CI workflow 已存在 | 真实云资源、域名证书、CDN、SSH、预算、联系人和供应商账号 | 仅脚本和 workflow 已准备；目标环境发布/回滚演练尚未执行 |

## 3. SQL 怎么导

### 3.1 安全导入

在仓库根目录选择一个尚不存在的临时数据库名执行:

```powershell
.\scripts\ci\mysql-smoke.ps1 -DbName dazhongdianping_local
```

要在独立临时库中执行完整导库 + 后端冒烟，并清理本次新建的库:

```powershell
.\scripts\ci\mysql-smoke.ps1 -DbName dazhongdianping_smoke -DropDatabaseAfter
```

`mysql-smoke.ps1` 默认只在 `-DbName` 尚不存在时创建数据库并依次 `source` `01_schema.sql`、`02_seed_data.sql`;同名库已存在时会拒绝执行,避免 `01_schema.sql` 的重建逻辑误清业务数据。已准备好的数据库应使用 `-SkipImport`,确需重置既有临时库时必须显式同时传入 `-DbName` 与 `-AllowDestructiveImport`。`-DropDatabaseAfter` 只接受显式传入的安全数据库标识符,并且只在 `finally` 中删除本次执行实际创建且所有权标记仍匹配的库。

### 3.2 三份 SQL 的作用

- `sql/mysql/00_all_in_one.sql`: 已退役的安全阻断桩,执行时直接报错,不再串联破坏性建表脚本。
- `sql/mysql/01_schema.sql`: 当前代码口径的建表脚本,已包含 `review_like`、`review_comment`、`review_report`、`review_merchant_reply`、`merchant_review_appeal`、`growth_points_log`。
- `sql/mysql/02_seed_data.sql`: 浏览数据、公开点评、待审/驳回审核案例、点评图片、点赞/评论演示数据、C 端演示账号。

### 3.3 导入后哪些表会直接有数据

- 会直接有演示数据:`category`、`city`、`area`、`merchant`、`shop`、`shop_photo`、`dish`、`home_banner`、`home_feed`、`app_user`、`review`、`review_image`、`review_like`、`review_comment`、`audit_task`。
- 会建表但默认留空:`search_history`、`verification_code`、`user_session`、`import_batch`、`review_report`、`review_merchant_reply`、`merchant_review_appeal`、`audit_log`、`growth_points_log`。
- 当前验证码限流和 `Idempotency-Key` 幂等缓存不依赖 MySQL 表,所以导库后别去找什么 `rate_limit` / `idempotency_record` 运行数据;这两块默认走本地内存,配置 `APP_STATE_STORE_PROVIDER=redis` 后可切 Redis。
- 留空不是漏写 SQL,而是这些表本来就更适合运行时真实产生:
  - `search_history`: 登录用户实际搜索商户列表后写入；每个 `user_id + region` 最多保留 20 条，超额按最近使用裁剪。
  - `verification_code`、`user_session`: 登录 / 刷新 token 运行时写入。
  - `import_batch`: 你真导一次商户种子后才会有批次记录。
  - `review_report`: 为了不把“第一次举报演示”直接堵死,默认不预置重复举报数据。
  - `audit_log`: 管理端真实操作后再产生日志才有意义。
  - `growth_points_log`: 当前只有真实提交点评后才会产生成长值 / 积分流水。
- 文件上传目录也不会靠 SQL 预置。你导完库以后第一次上传图片,文件才会落到 `backend/local-storage/uploads`。

### 3.4 这次和点评互动直接相关的表

- `review`: 点评主表,已包含 `like_count`、`comment_count` 聚合字段。
- `review_like`: 点赞记录表。
- `review_comment`: 评论记录表。
- `review_report`: 举报记录表。
- `audit_task`: 举报后补审时会生成点评待审任务。
- `review_merchant_reply`: 商户对公开点评的当前商家回复。
- `merchant_review_appeal`: 商户点评申诉草稿、待审、通过、驳回和失效状态。
- `growth_points_log`: 当前发点评奖励会各写一条成长值 / 积分流水。

### 3.5 导入后可以直接演示什么

- 首页 / 列表 / 详情浏览
- 商户详情页公开点评展示
- 点评详情页点赞 / 取消点赞
- 点评详情页评论列表查看与评论发布
- 点评详情页举报点评(登录后实际触发,会写 `review_report`)
- 写点评 / 编辑点评页本地图片上传
- 提交点评后查看 `GET /api/c/v1/user/me` 的成长值 / 积分 / 等级变化,以及 `GET /api/c/v1/user/growth/records`
- 登录后在头部直接查看 / 清空 / 单条删除当前区域搜索历史；Flutter 搜索页同样支持热词与搜索历史面板
- 资料页进入“成长值流水”查看成长值 / 积分变动明细
- 我的资料页绑定邮箱 / 手机号、修改密码
- 从点评评论区的演示用户昵称跳到公开用户主页
- 管理端点评审核页查看待审 / 驳回案例
- C 端密码登录后查看“我的资料”“我的点评”“我的点评详情”

## 4. 演示账号

### 4.1 C 端账号(来自 `sql/mysql/02_seed_data.sql`)

- 邮箱账号: `demo.cn@example.com` / `Demo123456`
- 手机号账号: `+447700900999` / `Demo123456`

### 4.2 管理端账号(来自 `sql/mysql/02_seed_data.sql`)

- 管理员账号: `admin` / `admin123456`；初始化脚本写入 `admin_user` 的 BCrypt `password_hash`，并同时写入内置角色、权限关联和 `CN/EU` 区域范围。

## 5. 验证情况

- `2026-07-25` `web` 运行 SEO 静态/快照脚本测试 `5` 条、全量测试 `117` 条通过；带本地 H2 后端、`PRERENDER_REGION=CN` 和 `PUBLIC_SITE_URL` 的 `npm run build:prerender:data` 实测生成 15 个路由（7 个静态入口 + 8 个真实详情快照），并生成 `prerender-manifest.json`、`sitemap.xml`、`robots.txt`。该结果不证明常驻 SSR、CN/EU 自动发布、真实域名缓存或目标环境部署已完成。
- `2026-07-21` 本轮按功能包执行聚焦验证：`web` 的浏览/SEO 相关 `vitest` 用例 `9` 个文件、`38` 条测试通过并完成构建；`merchant-web` 的布局、订单、预订和点评经营用例 `5` 个文件、`14` 条测试通过并完成构建。
- `backend` 已执行 `PublicBrowseControllerTest`、`UserPrivacyControllerTest`、`CommunityControllerTest`、`NotificationControllerTest` 和 `AdminAuditServiceTest` 聚焦测试；其中帖子正文/评论 `@提醒` 覆盖了审核通过后发通知、评论即时通知、同文去重以及跳过自己/不存在/重名用户。`app` 已执行社区、圈子、话题、首页和消息相关 `flutter test`；`scripts/ci/test-browser-e2e.ps1` 契约通过。
- 上述结果只覆盖本轮拆分提交的功能包，不替代全仓回归、真实 MySQL smoke、目标环境凭证联调或上线演练。

还没做的验证:

- 临时 `MySQL 8` 实例上的实际导库 + 默认配置启动冒烟最近一次于 `2026-07-12` 跑绿；本轮未重跑。宿主机 `MySQL80` 的现成 root 凭证仍不可用，但不是仓库侧阻塞。
- 带真实云 / 测试环境凭证的 Redis / S3 联调、SSH 发布 / 回滚演练还没在目标环境跑绿:仓库内脚本和 workflow 已补齐,但还需要实际 `DEPLOY_*`、`APP_S3_*`、`APP_STATE_STORE_PROVIDER` 等环境参数和主机密钥。
- 更多浏览器 E2E / 手工回归还没补完整；本轮文档记录的聚焦验证不能外推为所有业务和目标环境均已验收。

## 6. 下一步建议

如果你现在要继续往下干,最合理的顺序是:

1. `scripts/ci/mysql-smoke.ps1` 已经在临时 `MySQL 8` 实例上跑绿；如果要复用宿主机 `MySQL80`,先把它那套 root 凭证修好。
2. 接着给目标环境的 `MySQL / Redis / 对象存储 / SSH` 参数补齐,跑绿现有 `storage-smoke.ps1`、`deploy-release.ps1` 和 `rollback-release.ps1`。
3. 继续推进真实移动推送，以及真实支付、地图和 MySQL / Redis / S3 / SSH 凭证联调；本地达人认证、认证商户号、帖子转发、评论盖楼、帖子正文/评论 `@提醒`、话题广场/热榜已经落地。
