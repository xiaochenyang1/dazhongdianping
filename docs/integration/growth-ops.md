# 增长运营接口（攻略 / 创作者任务 / 实验开关 / 进程内消息）

区域取请求头 `X-Region`（`CN` / `EU`）。C 端写接口与需登录的读接口带 `Authorization: Bearer <accessToken>`。管理端另需对应 `operations:*` 权限。

列表响应为 `PageResult`：`list`、`total`、`page`、`pageSize`、`hasMore`。开关与实验管理列表是数组。

## 攻略

| 方法 | 路径 | 鉴权 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/c/v1/guides?page=&pageSize=` | 公开 | 仅当前区域、`status=2`、未删除 |
| GET | `/api/c/v1/guides/{id}` | 公开 | 含章节，按 `sortNo`、`id` 升序。不存在或未发布返回 404 |
| GET | `/api/admin/v1/guides` | `operations:guide:read` | 当前区域全部状态 |
| POST | `/api/admin/v1/guides` | `operations:guide:write` | body：`title`、`summary`、`coverUrl`、`cityId`、`status`（1 草稿 / 2 发布）、`sections[{heading,body,shopId,sortNo}]`。`messageKey=admin.guide_saved` |
| PUT | `/api/admin/v1/guides/{id}` | `operations:guide:write` | 更新文章并整表替换章节。`messageKey=admin.guide_saved` |
| POST | `/api/admin/v1/guides/{id}/status` | `operations:guide:write` | body：`{status}`。`messageKey=admin.guide_saved` |

## 创作者任务

| 方法 | 路径 | 鉴权 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/c/v1/creator/tasks` | 登录 | 当前区域开放任务及本人已领取的历史任务；领取后标题、要求、奖励取冻结值，任务下线后仍可提交。支持 `page/pageSize` |
| POST | `/api/c/v1/creator/tasks/{id}/claim` | 登录 | 领取时冻结任务条款和积分。重复领取 400。`messageKey=creator.claimed` |
| GET | `/api/c/v1/creator/evidence?type=post&page=1&pageSize=20` | 登录 | `type=review/post`；只列出本人、当前区域、内容审核通过且仍公开的作品。每页最多 50 条 |
| POST | `/api/c/v1/creator/tasks/{id}/submit` | 登录 | body：`evidenceType`、正整数 `evidenceId`、可选 `note`（最多 1000 字）；只允许状态 1/4，进入待审 3。待审期间相同作品和说明的重试返回原结果 |
| POST | `/api/c/v1/creator/tasks/{id}/complete` | 登录 | 旧的自助发奖入口已关闭，功能开关开启时返回 409；关闭时返回 403，不修改积分 |
| GET | `/api/admin/v1/creator/tasks` | `operations:creator:read` | 当前区域全部状态 |
| POST | `/api/admin/v1/creator/tasks` | `operations:creator:write` | body：`title`、`description`、`rewardPoints`、`status`（1 进行中 / 0 下线）。`messageKey=admin.creator_saved` |
| PUT | `/api/admin/v1/creator/tasks/{id}` | `operations:creator:write` | 同上，仅影响以后领取的条款。`messageKey=admin.creator_saved` |
| GET | `/api/admin/v1/creator/claims?status=3&page=1&pageSize=20` | `operations:creator:read` | 当前区域成果，可按 1/2/3/4 状态筛选；含冻结条款、用户、提交说明、版本、公开作品正文/图片/门店/评分及 `evidenceHash` |
| POST | `/api/admin/v1/creator/claims/{id}/review` | `operations:creator:write` | body：`approved`、`submissionVersion`、`evidenceHash`、可选 `note`。通过必须携带当前内容摘要；驳回必须填写原因，最多 1000 字 |

`claimStatus`：0 未领取、1 已领取、3 待审核、4 已驳回、2 已发放积分。流程为 `0 → 1 → 3 → 2`，或 `3 → 4 → 3`。每次有效提交增加 `submissionVersion`；旧版本审核返回 409。作品被删除、隐藏或修改（含图片变动）后，旧摘要不能通过审核，管理员须刷新核验或驳回。通过审核会在同一事务中写入完成时间、积分余额、一次 `growth_points_log(type=2, action=creator_task, biz_id=claimId)` 和审计记录；相同版本、相同结论的重试不重复发奖。

领取、提交和审核先锁账号，再锁任务/成果；发奖时继续锁作品，避免与账号注销交错后产生残留奖励。隐私导出 `activities.creatorClaims` 包含提交作品引用、说明、版本和审核原因；注销删除未发奖成果，已发奖成果解除账号关联并清除作品引用及个人说明。任务条款与必要奖励记录保留。

Web `/user/creator` 与 Flutter 提供作品分页选择、驳回原因及重提；后台 `/operations/creator` 提供成果审核和任务配置。接口、三端页面与 [迁移 28](../../sql/mysql/28_creator_task_review_migration.sql) 须配套部署。历史状态 2 保持终态；迁移优先从旧积分流水恢复实际奖励，不按后来修改的任务金额补发。

默认上线开关继续关闭：总开关关闭时 C 端创作者接口和后台通过审核均返回 403，后台仍可查看和驳回已有成果。独立功能测试须同时设置 `APP_LAUNCH_DEFERRED_FEATURES_ENABLED=true`；EU 还需 `APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED=true`。这些设置只用于隔离测试环境。

专项浏览器测试同时覆盖 CN 桌面和 EU 手机布局。使用自动启动的本地 H2 后端时，在 `web/` 执行：

```sh
APP_LAUNCH_DEFERRED_FEATURES_ENABLED=true APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED=true \
PLAYWRIGHT_REAL_BACKEND=1 PLAYWRIGHT_CREATOR_REVIEW=1 \
npx playwright test e2e/creator-review.spec.ts
```

迁移集成测试默认创建 MySQL 8.4 Docker 容器；无 Docker 的开发机可运行 `MYSQL_MIGRATION_TEST_SERVER=local bash scripts/ci/test-mysql-migration-integration.sh`，使用新建数据目录和私有 socket 启动本地 `mysqld`，结束后清理，不连接已有数据库。

本地装有 MySQL server/client 时，可执行 `python3 scripts/ci/creator-review-mysql.py`，自动创建临时 MySQL、应用迁移、启动三端并运行上述浏览器场景，结果保存在 `reports/creator-review-mysql/`。CI 和夜跑另有独立的 H2 创作者浏览器步骤，功能开关仅在该步骤内开启，普通首发回归保持关闭。

## 实验与开关

匿名读开关没有用户身份，分桶只使用 `flagKey` 的哈希，同一开关对所有人结果一致。

- `enabled=false` 或 `rolloutPercent<=0`：关闭
- `enabled=true` 且 `rolloutPercent>=100`：开启
- 否则：`Math.floorMod(Math.abs(flagKey.hashCode()), 100) < rolloutPercent` 时开启

| 方法 | 路径 | 鉴权 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/c/v1/flags` | 公开 | `[{flagKey, enabled}]`，仅当前区域，`enabled` 为上面的计算结果 |
| POST | `/api/c/v1/experiments/{id}/assign` | 登录 | body：`{variant}`，只接受 `A` 或 `B`。实验须为当前区域且 `status=1`。`(experiment_id, user_id)` 唯一，再次分配返回已有分组且不修改。`messageKey=experiment.assigned` |
| GET | `/api/admin/v1/flags` | `operations:experiment:read` | 原始 `enabled`、`rolloutPercent` |
| POST | `/api/admin/v1/flags` | `operations:experiment:write` | body：`flagKey`、`description`、`enabled`、`rolloutPercent`。同区域 `flagKey` 重复 400。`messageKey=admin.flag_saved` |
| PUT | `/api/admin/v1/flags/{id}` | `operations:experiment:write` | 同上。`messageKey=admin.flag_saved` |
| GET | `/api/admin/v1/experiments` | `operations:experiment:read` | 当前区域实验 |
| POST | `/api/admin/v1/experiments` | `operations:experiment:write` | body：`name`、`flagKey`、`status`（1 进行中 / 0 关闭）。`messageKey=admin.experiment_saved` |

## 进程内消息

`MessagePublisher.publish(topic, payload)` 是唯一实现，写入 `message_outbox`：`status=1`，`published_at` 为当前时间，`region` 取 `RegionContext`（未设置请求时与全站一致回落 `CN`）。不引入外部 broker。
