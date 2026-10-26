# EU 预发环境配置清单

更新时间：2026-10-15

当前候选基线以最新 `eu-pre-rc-*` tag 或通过 CI 的不可变提交 SHA 为准，不在本文内维护会过期的固定 SHA。

这份清单只记录变量名、位置和验收动作，不记录真实密钥。真实值应写入密钥管理系统、目标机私有 env 文件或 GitHub Environment variables/secrets。

## 1. 目标机运行环境

首发地理与币种范围已冻结：巴黎单城（`Europe/Paris`），EU 订单仅 EUR；其他 EU 城市停用，英国/GBP 不包含在本次预发验收中。

从 [`deploy/eu-pre.env.example`](../deploy/eu-pre.env.example) 复制一份到目标机或密钥管理系统，替换所有 `CHANGE_ME`。复制后的真实文件不得提交到仓库。

必须配置：

| 类型 | 变量 |
|---|---|
| 运行身份 | `APP_RUNTIME_MODE=pre` |
| 可信代理 | `APP_TRUSTED_PROXY_REGEX`：加单引号的锚定 Java 正则，只列出批准的 Ingress/负载均衡器 IPv4/IPv6 地址，用竖线分隔；IPv4 的点写作 `[.]` 或 `\.`，不接受网段、范围或通配符 |
| MySQL | `APP_DB_HOST`、`APP_DB_PORT`、`APP_DB_NAME`、`APP_DB_USERNAME`、`APP_DB_PASSWORD` |
| Redis | `APP_REDIS_HOST`、`APP_REDIS_PORT`、`APP_REDIS_PASSWORD`、`APP_REDIS_DATABASE`、`APP_STATE_STORE_PROVIDER=redis`、`APP_AD_CLICK_DEDUPE_SECONDS=1800` |
| 安全密钥 | `APP_AUTH_JWT_SECRET`、`APP_PAYMENT_NOTIFY_SECRET`，长度至少 32 字符 |
| 浏览器跨域 | `APP_CORS_ALLOWED_ORIGIN_PATTERNS`，逗号分隔列出三个 Web 的真实 HTTPS origin；禁止通配符、本机地址、userinfo 和路径 |
| 验证码总开关 | `APP_AUTH_VERIFICATION_MOCK_ENABLED=false`、`APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE=false`、`APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED=false` |
| SMTP 邮件 | `APP_AUTH_VERIFICATION_MAIL_ENABLED=true`、`APP_MAIL_HOST`、`APP_MAIL_PORT`、`APP_MAIL_USERNAME`、`APP_MAIL_PASSWORD`、`APP_MAIL_SMTP_AUTH=true`、`APP_MAIL_STARTTLS_ENABLED=true`、`APP_MAIL_HEALTH_ENABLED=true`、`APP_AUTH_VERIFICATION_MAIL_FROM`、`APP_AUTH_VERIFICATION_MAIL_SUBJECT`、`APP_AUTH_VERIFICATION_BRAND_NAME` |
| Twilio 国际短信 | `APP_AUTH_VERIFICATION_TWILIO_ENABLED=true`、`APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID`、`APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN`、`APP_AUTH_VERIFICATION_TWILIO_FROM` 或 `APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID`、`APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL=https://api.twilio.com`、`APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES=*`、`APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES=+86` |
| Stripe test mode | `APP_PAYMENT_STRIPE_ENABLED=true`、`APP_PAYMENT_STRIPE_SECRET_KEY=sk_test_*`、`APP_PAYMENT_STRIPE_ENDPOINT_SECRET=whsec_*`、`APP_PAYMENT_MOCK_ENABLED=false` |
| Elasticsearch | `APP_SEARCH_PROVIDER=elasticsearch`、`APP_SEARCH_BASE_URL`、`APP_SEARCH_INDEX_NAME`、`APP_SEARCH_FALLBACK_ON_ERROR=false` |
| S3 兼容存储 | `APP_FILE_STORAGE_PROVIDER=s3`、`APP_S3_BUCKET`、`APP_S3_REGION`、`APP_S3_ENDPOINT=https://...`、`APP_S3_PUBLIC_BASE_URL=https://...`、`APP_S3_ACCESS_KEY`、`APP_S3_SECRET_KEY` |
| 移动推送 | `APP_PUSH_ENABLED=false`，直到真实 FCM/APNs 真机 smoke 通过 |
| 延期功能 | 部署总开关 `APP_LAUNCH_DEFERRED_FEATURES_ENABLED=false`，同时关闭所有区域的延期能力；另保留 `APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED=false`、`APP_LAUNCH_EU_SECKILL_ENABLED=false`、`APP_LAUNCH_EU_GROUP_BUY_ENABLED=false` |
| Web/SEO | `PUBLIC_SITE_URL=https://...`、`PRERENDER_API_BASE_URL=https://...`、`PRERENDER_REGION=EU`、`VITE_DEFAULT_REGION=EU`、`VITE_API_BASE_URL=https://...`、`VITE_WS_BASE_URL=wss://...`、`VITE_STRIPE_PUBLISHABLE_KEY=pk_test_*` |

### EU 入口代理与广告点击 IP

- 广告匿名点击以 `HttpServletRequest.getRemoteAddr()` 做去重；应用代码不读取请求方可伪造的 `X-Forwarded-For`。
- Spring Boot/Tomcat 使用 native `RemoteIpValve`，默认不信任任何转发来源；预发启动时要求显式配置 `APP_TRUSTED_PROXY_REGEX`。该锚定正则应只列出实际 Ingress/负载均衡器的源 IP，并限制后端端口只能由这些代理访问。当前目标代理地址未知，模板不伪造网段。配置格式示例：`APP_TRUSTED_PROXY_REGEX='^(?:10[.]20[.]0[.]12|10[.]20[.]0[.]13)$'`；示例地址不可直接用于目标环境。
- 风控请求上下文、管理员登录审计和管理员操作审计也统一读取容器处理后的 `getRemoteAddr()`，不会自行选择客户端提供的 `X-Forwarded-For` 第一段。
- 应用只在请求内存中读取匿名访客 IP，并通过由服务密钥派生的 HMAC 指纹参与去重；原始 IP 不写入 `ad_click_log`、Redis 键或广告去重业务日志。EU `pre` 必须使用位于 EU 的 Redis；指纹键按默认 30 分钟过期。入口代理与基础设施访问日志的采集/留存由目标平台另行核验。
- 隐私告知中文草案（上线前需产品/隐私负责人审核）：`为防止广告点击刷量和重复计费，我们会在匿名广告点击场景短时使用请求来源 IP 计算去重指纹。指纹仅保存在欧盟区域的去重存储中，最长 30 分钟后过期；原始 IP 不写入广告点击明细。`
- EU 英文草案（上线前需产品/隐私负责人审核）：`To prevent ad-click abuse and duplicate billing, when you click an ad without signing in we temporarily use your IP address to create a deduplication fingerprint. The fingerprint is kept in our EU deduplication service for no more than 30 minutes. Your raw IP address is not written to the advertising click record.`
- 批准上述文案前，确认 Redis 主从/备份所在地域及去重键 TTL；同时向平台负责人核实 Ingress、负载均衡器和基础设施访问日志是否记录源 IP、存放地域与留存时长。若平台日志会保存 IP，应由隐私负责人决定是否补充告知内容。

### 代理验收步骤（目标环境参数齐备后执行）

1. 网络负责人确认后端监听端口只允许批准的 Ingress/负载均衡器访问：从代理节点连接后端端口应成功；从指定的非代理网络连接同一地址和端口应失败。不要把仅“后端没有公网地址”当作防火墙验收，仍需验证实际网络边界。
2. 建立一个仅供 EU `pre` 验收的低 CPC、有限日预算广告，并避免其他人同时点击。记录 campaign ID；点击会实际增加该预发广告的消耗。
3. 把 `PRE_BASE_URL` 设为不带尾斜杠的 EU `pre` HTTPS 地址，把 `CAMPAIGN_ID` 设为该专用广告 ID；出口 A 和 B 必须有不同的真实出口地址。从出口 A 经 HTTPS Ingress 对同一 campaign 连续匿名点击两次，两次分别带不同的伪造 `X-Forwarded-For` 值；预期 `data.charged` 依次为 `true`、`false`。例如：

   ```bash
   curl --fail-with-body -sS -X POST \
     "$PRE_BASE_URL/api/c/v1/ads/$CAMPAIGN_ID/click" \
     -H 'X-Region: EU' -H 'X-Forwarded-For: 198.51.100.10'
   curl --fail-with-body -sS -X POST \
     "$PRE_BASE_URL/api/c/v1/ads/$CAMPAIGN_ID/click" \
     -H 'X-Region: EU' -H 'X-Forwarded-For: 203.0.113.10'
   ```

4. 从有不同真实出口地址的出口 B，经同一 Ingress 对该 campaign 点击一次，并再次发送一个伪造的 `X-Forwarded-For` 值；预期 `data.charged=true`。A 的伪造头变化不应造成重复计费，B 的伪造头也不能与 A 合并去重。
5. 通过只读数据库会话核对专用 campaign 的 `ad_click_log`：三次请求应只有两条计费明细，`user_id` 均为 `0`，金额合计应等于两次 CPC。不要查询或导出任何请求 IP；验收后暂停专用 campaign。

   ```sql
   SELECT COUNT(*) AS billed_clicks,
          COALESCE(SUM(cost), 0) AS billed_amount,
          SUM(user_id <> 0) AS rows_with_user_id
   FROM ad_click_log
   WHERE campaign_id = <CAMPAIGN_ID> AND region = 'EU';
   ```

   预期为 `billed_clicks=2`、`rows_with_user_id=0`，且 `billed_amount` 等于该 campaign 的两次 CPC。若同一出口 A 的第二次点击仍计费，或出口 B 的点击被去重，应先检查 Ingress 的转发头覆盖/追加策略及 Tomcat 解析到的代理链，不要放行发布。

预检命令：

```bash
set -a
source /path/to/eu-pre.env
set +a
./scripts/ci/stripe-preflight.sh --check-cli
```

运行预检需要 Bash、Python 3 和 Stripe CLI。没有安装 Stripe CLI 时，先去掉 `--check-cli` 只能证明配置格式，不算真实支付验收。

## 2. 目标机数据库迁移文件

从 [`deploy/mysql-release.cnf.example`](../deploy/mysql-release.cnf.example) 复制真实文件到目标机私有路径，建议：

```text
/etc/dazhongdianping/mysql-release.cnf
```

要求：

- 权限为 `0400` 或 `0600`。
- 文件不放在 release bundle 目录内。
- GitHub Environment 变量 `DEPLOY_DB_DEFAULTS_FILE` 指向这个路径。
- 首次接管已有库时，临时设置 `DEPLOY_DB_BASELINE_VERSION`；确认迁移成功后移除。

## 3. GitHub `pre` Environment

源码 SHA 由工作流按选定版本自动注入：打包使用 `APP_RELEASE_COMMIT_SHA`，部署使用 `DEPLOY_EXPECTED_COMMIT_SHA`，不要将它们配置成长期固定值。本地执行时分别传入 `package-release.ps1 -CommitSha <40位SHA>` 和 `deploy-release.ps1 -ExpectedCommitSha <同一40位SHA>`；两者必须来自通过 CI 的版本。实际 `test/pre` 包须分别按对应环境构建，不能直接复用未注入配置的技术候选。

2026-10-14 只读核对 GitHub `pre` Environment 后，当前可见的变量名为 `DEPLOY_ADMIN_SERVICE`、`DEPLOY_BACKEND_SERVICE`、`DEPLOY_DB_MIGRATION_MODE`、`DEPLOY_MERCHANT_SERVICE`、`DEPLOY_SSH_PORT`、`DEPLOY_WEB_SERVICE`；没有配置 secret 名称。不得把此清单当作变量值或凭证核验。正式预发前仍需补齐下表中依赖目标环境的变量和 secrets。

Variables：

| 变量 | 示例/约束 |
|---|---|
| `DEPLOY_SSH_HOST` | 目标机域名或 IP |
| `DEPLOY_SSH_PORT` | 默认 `22` |
| `DEPLOY_SSH_USER` | 发布用户 |
| `DEPLOY_REMOTE_ROOT` | 非根绝对路径，例如 `/opt/dazhongdianping` |
| `DEPLOY_BACKEND_SERVICE` | 默认 `dzdp-backend` |
| `DEPLOY_WEB_SERVICE` | 默认 `dzdp-web` |
| `DEPLOY_ADMIN_SERVICE` | 默认 `dzdp-admin-web` |
| `DEPLOY_MERCHANT_SERVICE` | 默认 `dzdp-merchant-web` |
| `DEPLOY_SMOKE_URLS` | 逗号或换行分隔、无 userinfo 的绝对 HTTPS smoke URL；每项必须返回 `2xx` |
| `DEPLOY_DB_DEFAULTS_FILE` | 目标机 MySQL defaults 文件绝对路径 |
| `DEPLOY_DB_MIGRATION_MODE` | `apply` 或 `verify` |
| `DEPLOY_DB_BASELINE_VERSION` | 仅首次接管已有库时临时设置 |
| `DEPLOY_RELEASE_RETENTION_COUNT` | 可选，保留的旧版本数量，默认 `5`，范围 `1-100`；当前和 `previous` 始终保留 |
| `VITE_API_BASE_URL` | `https://...` |
| `VITE_WS_BASE_URL` | `wss://...` |
| `VITE_STRIPE_PUBLISHABLE_KEY` | `pk_test_*` |
| `PUBLIC_SITE_URL` | `https://...` |
| `PRERENDER_API_BASE_URL` | `https://...` |

Secrets：

| Secret | 用途 |
|---|---|
| `DEPLOY_SSH_PRIVATE_KEY` | GitHub Actions 发布用 SSH 私钥 |
| `DEPLOY_KNOWN_HOSTS` | 目标机 known_hosts 内容 |

## 4. 最小验收顺序

1. 隐私告知覆盖 30 分钟以内的广告反刷 IP 临时处理；完成可信代理配置，并从代理入口验证真实地址恢复、伪造转发头拒绝和后端不可绕过代理直连。
2. `stripe-preflight.sh --check-cli` 通过。
3. 目标机后端以 `APP_RUNTIME_MODE=pre` 启动成功。
4. MySQL、Redis、S3、Elasticsearch health/smoke 通过。
5. SMTP 测试邮箱真实收到验证码。
6. 至少一个欧洲手机号通过 Twilio 真实收到验证码。
7. Stripe CLI 转发 `payment_intent.succeeded` 到后端，Webhook 验签通过并发券。
8. 非法 Stripe 签名返回 `400`。
9. EU Stripe 订单不能通过 `mock-complete` 绕过支付。
10. 发布包 SHA-256 校验、部署 smoke 和回滚演练通过；部署与回滚 smoke 均只接受 `2xx`。

## 5. 当前阻塞

- Stripe CLI 1.50.1 已安装，但没有真实 Stripe test 凭证与 Stripe CLI 验收结果。
- 没有 SMTP/Twilio 凭证与送达 smoke 结果。
- 没有目标机 SSH、MySQL、Redis、S3、Elasticsearch、HTTPS/WSS 域名配置。
- 当前核对到的 GitHub `pre` Environment 只有 6 个固定变量名、没有 secret 名称；目标机、数据库、Web/SEO 变量、SMTP/Twilio/Stripe 凭证和 SSH secrets 均未齐备。`prod` Environment 尚未创建。
- 目标代理网段和代理直连隔离尚未配置/验收。因此当前去重代码只在直连请求场景下能准确区分匿名客户端。

## 6. 已完成的仓库侧准备

本轮巴黎首发和候选验证记录见 [2026-10-14 执行记录](巴黎首发优化与发布候选验证-2026-10-14.md)。以下旧候选保留为历史记录：

- `eu-pre-rc-20260816-3` 已发布；标签 CI 的全量验证和 MySQL 迁移集成作业通过。
- PR #1 已合入 `main`；合并提交的主干 CI 全部通过。
- 已执行一次不注入伪造域名或支付配置的完整本地打包，ZIP、旁车 SHA-256、release manifest、后端 JAR、三个 Web `dist`、迁移 runner、迁移清单和 `03-14` 共 12 个迁移文件均已核验。
- 自动 `release` 已验证配置缺失时只完成门禁检查，打包、上传和部署均跳过。此项不替代真实 `test`/`pre` 发布、smoke 或回滚演练。
