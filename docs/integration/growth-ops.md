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
| GET | `/api/c/v1/creator/tasks` | 登录 | 当前区域进行中的任务。`claimStatus`：0 未领、1 已领、2 已完成 |
| POST | `/api/c/v1/creator/tasks/{id}/claim` | 登录 | 领取。重复领取 400。`messageKey=creator.claimed` |
| POST | `/api/c/v1/creator/tasks/{id}/complete` | 登录 | 仅已领取可完成。状态改为 2，写 `completed_at`，并把 `reward_points` 加到 `app_user.points` 一次，同时插入 `growth_points_log`（`type=2`，`action=creator_task`，`biz_id=claimId`）。`messageKey=creator.completed` |
| GET | `/api/admin/v1/creator/tasks` | `operations:creator:read` | 当前区域全部状态 |
| POST | `/api/admin/v1/creator/tasks` | `operations:creator:write` | body：`title`、`description`、`rewardPoints`、`status`（1 进行中 / 0 下线）。`messageKey=admin.creator_saved` |
| PUT | `/api/admin/v1/creator/tasks/{id}` | `operations:creator:write` | 同上。`messageKey=admin.creator_saved` |

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
