# EU 首发与预发发布基线

更新时间：2026-11-13

预发布加固已通过 PR #1 合入 `main`。后续发布仍必须使用通过 CI 的不可变提交 SHA 或最新 `eu-pre-rc-*` 标签，不把可移动分支名当作发布版本。

创作者成果提交、人工审核与一次性发奖已通过 PR #28 合入主干，新增第 28 号迁移；秒杀真实订单、并发库存、支付发券、取消/到期释放、退款与核销已通过 PR #30 合入主干，新增第 29 号迁移；拼团独立成员订单、并发库存、全员付款成团发券、到期关单与自动退款、运营告警/修复、截止提醒和分层灰度已通过 PR #35 合入，终态退款人工核验与本地幂等补齐已通过 PR #36 收口。第 30、31 号迁移保持不变，三项能力的默认上线开关仍关闭。创作者主干 `246d90b` 的证据见 [创作者交付记录](创作者任务提交审核与发奖-2026-11-06.md#主干与技术候选)；秒杀主干 `24fba53` 的 CI、nightly 与技术候选见 [秒杀交付记录](秒杀订单交易闭环-2026-11-06.md#主干与技术候选)；拼团历史技术包 `eu-pre-rc-20261108-2` 与包内 JAR 启动证据见 [拼团交付记录](拼团订单交易与灰度运营-2026-11-08.md)。此前隐私数据域收尾和团购标题搜索分别通过 PR #20 / #21 合入主干；扫码交付见 [验证记录](商户摄像头扫码验证-2026-10-24.md)。上述延期能力在目标环境独立验收前仍不得开放；部署准备、供应商送达/支付、商户试用及备份/回滚按 [执行与验收台账](EU预发执行与验收台账.md) 留证，尚无真实目标环境部署通过记录。

当前冻结源码候选为 `eu-pre-rc-20261113-1`，绑定不可变主干 `c0720f877c2ee9d36c6c8ad7fb19afd534f75576`。PR #48 已补签名 iOS IPA 流水线，PR #49–#52 已依次补 nightly 测试隔离、候选完整门禁、隔离 smoke 服务编排和远端 `test/EU` 浏览器验收；这些能力均已通过当前 SHA 的 CI/nightly，但尚未生成带真实环境参数的部署包，也没有目标机执行证据。

## 首发范围

首发范围已冻结为巴黎单城、仅 EUR，目标是完成一条真实可验收的欧洲用户链路。巴黎时区为 `Europe/Paris`；其他 EU 城市在首发中停用，不能创建或接收预订流量。EU 后端订单币种固定为 EUR，GBP 不在本轮范围内。

开放功能沿用下列既有 EU 产品基线：

- PC Web：浏览、搜索、门店详情、点评、团购、预订、用户中心和社区只读内容。
- Flutter：登录、浏览、点评、团购、预订、通知、隐私中心和已落地的社区能力。
- 商户端：门店、团购、预订、订单/退款、核销和点评经营。
- 管理端：RBAC、基础数据、内容审核、商户治理、订单/退款、运营和隐私任务。

创作者奖励、秒杀和拼团通过部署总开关 `APP_LAUNCH_DEFERRED_FEATURES_ENABLED=false` 在所有区域默认关闭：CN、EU 或省略 `X-Region` 都不能领取奖励或参与延期活动，避免未验收能力影响共用余额和交易。后端拒绝相关调用，Web/Flutter 隐藏入口，Web 直达路由回首页。预发配置检查要求总开关及三个 `APP_LAUNCH_EU_*_ENABLED` 开关均显式为 `false`。只有在独立功能验收环境中才可打开总开关；打开后 CN 按各功能当前实现处理，EU 再由各功能开关决定。创作者在两区均须提交成果并通过人工审核，旧 `/complete` 不能自助发奖；秒杀和拼团购买均生成活动订单并沿现有支付、发券、退款和核销链路履约。拼团还受数据库 `group_buy` 总开关及活动、门店、城市规则约束，默认规则全部关闭；完成目标环境资金、库存、告警和运营处置验收前不得开放。门店普通团购和在线预订仍属于既有核心交易链路。

CN 保留为代码兼容区域，但不作为本轮真实支付验收目标；CN 支付仍是 `alipay_mock`。

## 本轮明确延期

- Google Maps：列表、原生交互地图和定位代码已落地，但真实受限 Key 与真机 smoke 仍延期，不作为 EU 预发通过条件。
- FCM/APNs：服务端和客户端适配器已完成，但没有真实凭证和真机 smoke 前不宣称上线。
- 常驻 SSR、独立域名/CDN 缓存和正式商店发布：留到预发基础链路稳定后执行。

## 已完成的发布证据

巴黎首发和时区证据见 [10 月 14 日执行记录](巴黎首发优化与发布候选验证-2026-10-14.md)，跨区域奖励修复及本地回归见 [10 月 15 日执行记录](跨区域奖励修复与候选验证-2026-10-15.md)。最终候选以同一不可变 SHA 的 CI、nightly 和发布 manifest 为准。下列 8 月记录保留为历史证据，不能代替本轮验证。

- `eu-pre-rc-20261113-1` 指向 `c0720f877c2ee9d36c6c8ad7fb19afd534f75576`；其 [tag CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43381478323) 与 [手工 nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43379749086) 均通过。CI 覆盖后端 711 项、用户 Web 293 项、管理端 193 项、商户端 77 项、Flutter 691 项，以及真实 MySQL/Redis/S3/Elasticsearch、浏览器 smoke/E2E 和 03–31 迁移集成。
- 当前标签触发的 `release` 仍因 `test` Environment 不完整而没有打包、上传、SSH、部署或验收步骤；绿色/跳过结论只证明 fail-closed 条件生效，不构成目标环境发布证据。

- `eu-pre-rc-20260816-3` 已发布并指向提交 `ca683d14a8661ab05fb0d6ede51dcae98a63b29f`；标签 CI 运行 `31983461176` 的全量验证和 MySQL 迁移集成作业均通过。
- PR #1 已以 merge commit `71ee8f8e6215a04c4af5fba5d1b3b0688aa2a83c` 合入 `main`；主干 CI 运行 `31984095560` 的全量验证和 MySQL 迁移集成作业均通过。
- 已使用 PowerShell 7.6.5 执行一次完整本地发布打包。`eu-pre-rc-20260816-3` ZIP 包含后端 JAR、三个 Web `dist`、`03-14` 数据库迁移、迁移清单、迁移 runner 和 release manifest；ZIP 完整性、旁车 SHA-256 以及 12 个迁移文件的包内校验均通过。本地制品 SHA-256 为 `e6d04bd84116c7d6f6e848e207e55fb067b5ea7d22dab3967805ad6d2010c3e8`。
- 合并后自动 `release` 运行 `31984736249` 成功完成配置门禁。由于 `test` 目标环境未配置完整，checkout、打包、上传、SSH 和部署步骤全部按设计跳过；该结果只证明 fail-closed 门禁有效，不算测试环境部署通过。

## 预发配置

预发配置分成两套，缺一套都不能发布：

1. 目标机运行环境：从 [`deploy/eu-pre.env.example`](../deploy/eu-pre.env.example) 复制到密钥管理系统或目标机，替换所有 `CHANGE_ME`。另将 [`deploy/mysql-release.cnf.example`](../deploy/mysql-release.cnf.example) 安装到目标机私有路径（建议 `/etc/dazhongdianping/mysql-release.cnf`），设置 `0400/0600`。
2. GitHub `pre` Environment：服务器发布至少配置 `DEPLOY_SSH_*`、`DEPLOY_REMOTE_ROOT`、`DEPLOY_DB_DEFAULTS_FILE`、`DEPLOY_DB_MIGRATION_MODE`、`VITE_API_BASE_URL`、`VITE_WS_BASE_URL`、`VITE_STRIPE_PUBLISHABLE_KEY`、`PUBLIC_SITE_URL`、`PRERENDER_API_BASE_URL` 与 SSH secrets；Android 发布再配置 `DZDP_ANDROID_APPLICATION_ID`、`DZDP_APP_API_BASE_URL` 和签名 secrets。移动流水线复用 `PUBLIC_SITE_URL` 与 `VITE_STRIPE_PUBLISHABLE_KEY` 注入分享域名和 Stripe。

首次接管已有库时，GitHub Environment 还需设置一次性 `DEPLOY_DB_BASELINE_VERSION`，确认成功后立即移除。目标机环境就绪后执行：

```bash
set -a
source /path/to/eu-pre.env
set +a
./scripts/ci/stripe-preflight.sh --check-cli
```

预发必须满足：运行身份为严格 `pre`、Stripe test mode 开启、mock 支付关闭、验证码 mock/回显/控制台通道关闭、SMTP 邮件与 Twilio 国际短信均可配置、Redis 状态存储、HTTPS S3 endpoint/public URL、明确的 Elasticsearch endpoint/index 且关闭 fallback、EU SEO 构建、HTTPS Web/API 地址和 WSS 通知地址。`APP_CORS_ALLOWED_ORIGIN_PATTERNS` 必须逐项列出真实 HTTPS Web origin，不允许通配符、本机地址、userinfo 或路径。SMTP 必须启用认证、STARTTLS 和健康检查；Twilio 必须覆盖国际号码并排除默认交给阿里云的 `+86`。阿里云在 EU 首发门禁中为可选 CN 通道，启用时才校验其 AccessKey、签名、模板和 `+86` 路由。预检脚本会执行这些格式和模式检查，但不会输出密钥内容。

## 通过条件

构建时还需 `VITE_DEFAULT_REGION=EU`，保证新访客默认进入 EU；发布打包脚本按每份 Web 制品的预渲染区域注入默认区域，并写入 `release-manifest.json` 的 `webRuntime.defaultRegion`。已保存的合法 CN/EU 选择仍保留。

1. 后端、三个 Web 前端和 Flutter 全量测试/构建通过。
2. MySQL、Redis、S3、Elasticsearch smoke 通过。
3. SMTP 测试邮箱和至少一个欧洲手机号能真实收到验证码；无匹配通道时继续返回 `503`，不跨类型或跨号码范围回退。
4. Stripe CLI 能把 `payment_intent.succeeded` 转发到后端，Webhook 验签通过并发券。
5. 非法 Stripe 签名返回 `400`；EU Stripe 订单不能通过 `mock-complete` 绕过支付。
6. EU/CN 区域隔离、订单幂等、退款失败回滚均通过。
7. 发布包、SHA-256、部署 smoke 和回滚演练至少在 `test`/`pre` 环境各执行一次；每个部署 smoke URL 必须是无 userinfo 的绝对 HTTPS URL 并返回 `2xx`，失败会重试并触发自动回滚，回滚后再次验证同一组 URL。远端默认保留当前、previous 和 5 个旧版本，smoke 成功后才清理更旧目录与已上传 ZIP。

## 当前阻塞

- 当前开发机已安装 Stripe CLI 1.50.1，但没有真实 `sk_test_`、`pk_test_`、`whsec_` 凭证和登录态，真实支付验收无法在本地完成。
- 没有可验收的 SMTP 发信域名/账号和 Twilio Account/Messaging Service，邮件与欧洲短信送达 smoke 无法在本地完成。
- 没有目标机 SSH、数据库、Redis、S3、Elasticsearch 和域名配置，预发部署无法执行。
- 2026-11-13 实时复核 GitHub Environment：`test` variables/secrets 均为 0；`pre` 只有 SSH 端口、四个服务名和数据库迁移模式 6 个固定变量，secrets 为 0，且没有 required reviewer；`prod` 尚未创建。Android `mobile-release` 与 iOS `ios-release` 均无运行记录；自动 `deploy-test` 继续在配置不完整时按门禁跳过。
- 当前候选的 [`test/EU` readiness](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43387040998) 已确认 CI 就绪，但 Environment 缺 6 个变量和 7 个 secret，且没有目标机证据，因此 `readyForDeployment=false`；报告明确未修改外部状态。
- 上述运行早于手工 test 远端浏览器验收接线；当前门禁又要求 4 个验收 origin variables 和 4 个浏览器 credential secrets，旧报告不能代替新契约下的 readiness。
- Google Maps 仍是明确延期项，不影响本轮 EU 列表浏览验收。

对应的代码级支付状态见 [`STRIPE_PAYMENT_STATUS.md`](STRIPE_PAYMENT_STATUS.md)，真实环境填值清单见 [`EU预发环境配置清单.md`](EU预发环境配置清单.md)，完整功能矩阵见 [`当前已完成功能与SQL导入说明.md`](当前已完成功能与SQL导入说明.md) §2.2。
