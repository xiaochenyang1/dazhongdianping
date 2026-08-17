# EU 首发与预发发布基线

更新时间：2026-08-17

预发布加固已通过 PR #1 合入 `main`。后续发布仍必须使用通过 CI 的不可变提交 SHA 或最新 `eu-pre-rc-*` 标签，不把可移动分支名当作发布版本。

## 首发范围

首发先冻结为 `EU`，目标是完成一条真实可验收的欧洲用户链路：

- PC Web：浏览、搜索、门店详情、点评、团购、预订、用户中心和社区只读内容。
- Flutter：登录、浏览、点评、团购、预订、通知、隐私中心和已落地的社区能力。
- 商户端：门店、团购、预订、订单/退款、核销和点评经营。
- 管理端：RBAC、基础数据、内容审核、商户治理、订单/退款、运营和隐私任务。

CN 保留为代码兼容区域，但不作为本轮真实支付验收目标；CN 支付仍是 `alipay_mock`。

## 本轮明确延期

- Google Maps：列表、原生交互地图和定位代码已落地，但真实受限 Key 与真机 smoke 仍延期，不作为 EU 预发通过条件。
- FCM/APNs：服务端和客户端适配器已完成，但没有真实凭证和真机 smoke 前不宣称上线。
- 常驻 SSR、独立域名/CDN 缓存和正式商店发布：留到预发基础链路稳定后执行。

## 已完成的发布证据

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
- GitHub 当前已有 `test` 和 `pre` Environment；`pre` 已写入 SSH 端口、四个服务名和数据库迁移模式等非敏感固定值，但目标机地址、发布目录、数据库 defaults 路径、Web/SEO URL 与 SSH secrets 仍未配置，`prod` 尚未创建。`mobile-release` 尚无运行记录；合并后的自动 `deploy-test` 已实际验证会在环境未配置完整时按门禁跳过。
- Google Maps 仍是明确延期项，不影响本轮 EU 列表浏览验收。

对应的代码级支付状态见 [`STRIPE_PAYMENT_STATUS.md`](STRIPE_PAYMENT_STATUS.md)，真实环境填值清单见 [`EU预发环境配置清单.md`](EU预发环境配置清单.md)，完整功能矩阵见 [`当前已完成功能与SQL导入说明.md`](当前已完成功能与SQL导入说明.md) §2.2。
