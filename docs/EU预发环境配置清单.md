# EU 预发环境配置清单

更新时间：2026-08-17

当前候选基线以最新 `eu-pre-rc-*` tag 或通过 CI 的不可变提交 SHA 为准，不在本文内维护会过期的固定 SHA。

这份清单只记录变量名、位置和验收动作，不记录真实密钥。真实值应写入密钥管理系统、目标机私有 env 文件或 GitHub Environment variables/secrets。

## 1. 目标机运行环境

从 [`deploy/eu-pre.env.example`](../deploy/eu-pre.env.example) 复制一份到目标机或密钥管理系统，替换所有 `CHANGE_ME`。复制后的真实文件不得提交到仓库。

必须配置：

| 类型 | 变量 |
|---|---|
| 运行身份 | `APP_RUNTIME_MODE=pre` |
| MySQL | `APP_DB_HOST`、`APP_DB_PORT`、`APP_DB_NAME`、`APP_DB_USERNAME`、`APP_DB_PASSWORD` |
| Redis | `APP_REDIS_HOST`、`APP_REDIS_PORT`、`APP_REDIS_PASSWORD`、`APP_REDIS_DATABASE`、`APP_STATE_STORE_PROVIDER=redis` |
| 安全密钥 | `APP_AUTH_JWT_SECRET`、`APP_PAYMENT_NOTIFY_SECRET`，长度至少 32 字符 |
| 浏览器跨域 | `APP_CORS_ALLOWED_ORIGIN_PATTERNS`，逗号分隔列出三个 Web 的真实 HTTPS origin；禁止通配符、本机地址、userinfo 和路径 |
| 验证码总开关 | `APP_AUTH_VERIFICATION_MOCK_ENABLED=false`、`APP_AUTH_VERIFICATION_EXPOSE_MOCK_CODE=false`、`APP_AUTH_VERIFICATION_DEV_CONSOLE_ENABLED=false` |
| SMTP 邮件 | `APP_AUTH_VERIFICATION_MAIL_ENABLED=true`、`APP_MAIL_HOST`、`APP_MAIL_PORT`、`APP_MAIL_USERNAME`、`APP_MAIL_PASSWORD`、`APP_MAIL_SMTP_AUTH=true`、`APP_MAIL_STARTTLS_ENABLED=true`、`APP_MAIL_HEALTH_ENABLED=true`、`APP_AUTH_VERIFICATION_MAIL_FROM`、`APP_AUTH_VERIFICATION_MAIL_SUBJECT`、`APP_AUTH_VERIFICATION_BRAND_NAME` |
| Twilio 国际短信 | `APP_AUTH_VERIFICATION_TWILIO_ENABLED=true`、`APP_AUTH_VERIFICATION_TWILIO_ACCOUNT_SID`、`APP_AUTH_VERIFICATION_TWILIO_AUTH_TOKEN`、`APP_AUTH_VERIFICATION_TWILIO_FROM` 或 `APP_AUTH_VERIFICATION_TWILIO_MESSAGING_SERVICE_SID`、`APP_AUTH_VERIFICATION_TWILIO_API_BASE_URL=https://api.twilio.com`、`APP_AUTH_VERIFICATION_TWILIO_ROUTE_PREFIXES=*`、`APP_AUTH_VERIFICATION_TWILIO_EXCLUDED_ROUTE_PREFIXES=+86` |
| Stripe test mode | `APP_PAYMENT_STRIPE_ENABLED=true`、`APP_PAYMENT_STRIPE_SECRET_KEY=sk_test_*`、`APP_PAYMENT_STRIPE_ENDPOINT_SECRET=whsec_*`、`APP_PAYMENT_MOCK_ENABLED=false` |
| Elasticsearch | `APP_SEARCH_PROVIDER=elasticsearch`、`APP_SEARCH_BASE_URL`、`APP_SEARCH_INDEX_NAME`、`APP_SEARCH_FALLBACK_ON_ERROR=false` |
| S3 兼容存储 | `APP_FILE_STORAGE_PROVIDER=s3`、`APP_S3_BUCKET`、`APP_S3_REGION`、`APP_S3_ENDPOINT=https://...`、`APP_S3_PUBLIC_BASE_URL=https://...`、`APP_S3_ACCESS_KEY`、`APP_S3_SECRET_KEY` |
| 移动推送 | `APP_PUSH_ENABLED=false`，直到真实 FCM/APNs 真机 smoke 通过 |
| Web/SEO | `PUBLIC_SITE_URL=https://...`、`PRERENDER_API_BASE_URL=https://...`、`PRERENDER_REGION=EU`、`VITE_API_BASE_URL=https://...`、`VITE_WS_BASE_URL=wss://...`、`VITE_STRIPE_PUBLISHABLE_KEY=pk_test_*` |

预检命令：

```bash
set -a
source /path/to/eu-pre.env
set +a
./scripts/ci/stripe-preflight.sh --check-cli
```

没有安装 Stripe CLI 时，先去掉 `--check-cli` 只能证明配置格式，不算真实支付验收。

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

当前远程仓库已创建 `pre` Environment，并已写入以下无需外部资源即可确定的固定变量：`DEPLOY_SSH_PORT=22`、四个默认服务名和 `DEPLOY_DB_MIGRATION_MODE=apply`。正式预发前仍需补齐下表中依赖目标环境的变量和 secrets。

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

1. `stripe-preflight.sh --check-cli` 通过。
2. 目标机后端以 `APP_RUNTIME_MODE=pre` 启动成功。
3. MySQL、Redis、S3、Elasticsearch health/smoke 通过。
4. SMTP 测试邮箱真实收到验证码。
5. 至少一个欧洲手机号通过 Twilio 真实收到验证码。
6. Stripe CLI 转发 `payment_intent.succeeded` 到后端，Webhook 验签通过并发券。
7. 非法 Stripe 签名返回 `400`。
8. EU Stripe 订单不能通过 `mock-complete` 绕过支付。
9. 发布包 SHA-256 校验、部署 smoke 和回滚演练通过；部署与回滚 smoke 均只接受 `2xx`。

## 5. 当前阻塞

- Stripe CLI 1.50.1 已安装，但没有真实 Stripe test 凭证与 Stripe CLI 验收结果。
- 没有 SMTP/Twilio 凭证与送达 smoke 结果。
- 没有目标机 SSH、MySQL、Redis、S3、Elasticsearch、HTTPS/WSS 域名配置。
- GitHub `pre` Environment 已创建但尚未补齐目标机、数据库、Web/SEO 变量和 SSH secrets；`prod` Environment 尚未创建。

## 6. 已完成的仓库侧准备

- `eu-pre-rc-20260816-3` 已发布；标签 CI 的全量验证和 MySQL 迁移集成作业通过。
- PR #1 已合入 `main`；合并提交的主干 CI 全部通过。
- 已执行一次不注入伪造域名或支付配置的完整本地打包，ZIP、旁车 SHA-256、release manifest、后端 JAR、三个 Web `dist`、迁移 runner、迁移清单和 `03-14` 共 12 个迁移文件均已核验。
- 自动 `release` 已验证配置缺失时只完成门禁检查，打包、上传和部署均跳过。此项不替代真实 `test`/`pre` 发布、smoke 或回滚演练。
