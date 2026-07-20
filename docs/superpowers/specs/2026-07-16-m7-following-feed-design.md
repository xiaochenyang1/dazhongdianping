# M7 关注关系与关注流设计

## 1. 目标

在帖子内容闭环之上完成 M7 第二阶段的第一条关系链闭环：用户可在 Flutter 关注其他用户、查看粉丝与关注列表，并浏览当前区域内被关注者发布的审核通过帖子；被关注者收到全局站内通知。PC Web 继续保持只读，只展示公开关注统计。关注关系与相关个人数据纳入隐私导出和注销治理。

本阶段建立的是可验证、可治理的关注关系，不包含私信、圈子、拉黑、算法推荐或真实移动推送。

## 2. 范围

### 2.1 包含

- 关注与取关，使用显式、幂等的写接口。
- 公开粉丝数、关注数、粉丝列表和关注列表。
- 当前登录用户是否已关注目标用户。
- Flutter 推荐流/关注流双 Tab。
- Flutter 公开用户主页、关注按钮、粉丝与关注列表。
- 帖子列表和详情进入作者公开主页。
- 首次关注成功时生成 `social.follow` 全局站内通知。
- `GLOBAL` 通知在 CN/EU 均可见，已读状态全局共享。
- `follows` 隐私导出模块和注销到期清理。
- PC Web 公开用户主页展示粉丝数与关注数，不提供关注操作。

### 2.2 不包含

- 私信、会话、消息举报和拉黑。
- 同城、同校或兴趣圈子。
- 关注推荐、通讯录匹配、达人认证。
- 算法推荐流、关注流预计算收件箱或消息队列扇出。
- 关注动态的 FCM/APNs 推送。
- PC Web 关注、取关或发帖互动。

## 3. 核心语义

### 3.1 全局关注关系

关注的是用户，不是区域。用户在 EU 关注另一用户后切换到 CN，关注关系仍然存在，公开主页仍显示已关注。

关注流继续遵守内容区域隔离：请求 `GET /api/c/v1/posts/following` 时，只返回当前 `X-Region` 下被关注者审核通过、状态正常且未删除的帖子。切区只改变流内容，不改变关注关系。

### 3.2 幂等写接口

关注不使用切换式接口。网络重试时，切换式 `POST` 可能把刚建立的关注反向取消，因此采用显式状态接口：

- `PUT /api/c/v1/follow/{userId}`：确保当前用户已关注目标用户。
- `DELETE /api/c/v1/follow/{userId}`：确保当前用户未关注目标用户。

重复关注和重复取关均返回成功状态，不产生重复关系或重复通知。

### 3.3 公开关系数据

粉丝数、关注数、粉丝列表和关注列表属于公开主页信息。匿名用户可以查看列表；只有登录用户响应中才计算 `followedByCurrentUser`。

## 4. 数据模型

### 4.1 `user_follow`

新增全局关系表：

- `id BIGINT`：主键。
- `follower_user_id BIGINT`：关注发起者。
- `followed_user_id BIGINT`：被关注者。
- `created_at DATETIME`：关系建立时间。
- 唯一索引 `(follower_user_id, followed_user_id)`：禁止重复关系。
- 查询索引 `(followed_user_id, created_at, id)`：粉丝列表。
- 查询索引 `(follower_user_id, created_at, id)`：关注列表和关注流。

表中不保存 `region`，也不使用软删除。取关直接删除关系。粉丝数和关注数在当前阶段通过索引实时统计，不向 `app_user` 写缓存计数，避免引入计数一致性债务。

服务层拒绝 `follower_user_id == followed_user_id`。数据库唯一索引处理并发重复关注，服务将唯一冲突归一化为“已关注”。

### 4.2 `user_notification` 扩展

现有通知表增加可空字段：

- `actor_user_id BIGINT NULL`：触发通知的用户。

既有订单、预订和系统通知保持为空。关注通知记录关注者 ID，便于注销治理，不通过解析 `content` 或 `link_url` 猜来源用户。

全局社交通知使用 `region='GLOBAL'`。通知查询、未读计数和确认已读均允许当前区域数据与 `GLOBAL` 数据；区域业务通知原有语义不变。

## 5. 后端架构

### 5.1 Social 模块

新增独立 `social` 模块，包含：

- `SocialController`：关注写接口、粉丝列表、关注列表。
- `SocialService`：目标用户校验、自关注校验、幂等写入、计数、通知创建。
- `SocialMapper`：关系增删、存在性查询、分页列表与计数。
- 请求/响应模型：关系状态和公开关系用户摘要。

`community` 模块不负责维护关注关系，只在关注流查询中连接 `user_follow` 与 `post`。这样关系逻辑和内容逻辑可以独立演进。

### 5.2 公开用户主页

扩展现有 `GET /api/c/v1/user/{userId}` 响应：

- `followerCount`
- `followingCount`
- `followedByCurrentUser`

匿名访问时 `followedByCurrentUser=false`。查看本人时同样为 `false`，客户端不展示关注按钮。

### 5.3 API

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| PUT | `/api/c/v1/follow/{userId}` | 登录 | 幂等关注 |
| DELETE | `/api/c/v1/follow/{userId}` | 登录 | 幂等取关 |
| GET | `/api/c/v1/user/{userId}/followers` | 公开 | 粉丝列表，`page/pageSize` |
| GET | `/api/c/v1/user/{userId}/following` | 公开 | 关注列表，`page/pageSize` |
| GET | `/api/c/v1/posts/following` | 登录 | 当前区域关注流，`page/pageSize` |

关注写响应：

```json
{
  "userId": 9002,
  "following": true,
  "followerCount": 18
}
```

关系列表项返回最小公开摘要：`id/nickname/avatar/signature/level/followerCount/followedByCurrentUser/followedAt`。`pageSize` 最大为 50。

### 5.4 关注流查询

关注流通过 `user_follow` 连接 `post`：

- `user_follow.follower_user_id = 当前用户`。
- `post.user_id = user_follow.followed_user_id`。
- `post.region = 当前 X-Region`。
- `post.audit_status = 1`。
- `post.status = 1`。
- `post.is_deleted = 0`。
- 排序为 `post.created_at DESC, post.id DESC`。

第一版沿用现有 `page/pageSize` 分页，不增加推荐权重、游标协议或预计算 feed 表。

## 6. 通知设计

### 6.1 创建规则

只有关系从不存在变为存在时创建通知：

- `type`: `social.follow`
- `region`: `GLOBAL`
- `user_id`: 被关注者
- `actor_user_id`: 关注者
- `title`: `新增关注`
- `content`: `{关注者昵称} 关注了你`
- `link_url`: `/users/{关注者 ID}`

重复 `PUT` 不创建第二条通知；取关不创建通知。

关系写入与通知记录创建处于同一数据库事务。WebSocket 推送在事务提交后执行，防止数据库回滚后客户端仍收到不存在的通知。

### 6.2 查询和 WebSocket

当客户端位于 CN 时，通知 REST 查询条件为 `region IN ('CN', 'GLOBAL')`；EU 同理。确认一条 `GLOBAL` 通知已读后，切换区域时仍保持已读。

`NotificationSessionRegistry` 增加向指定用户全部区域会话发送的方法。`GLOBAL` 通知通过该方法推送；区域通知继续只发送到对应区域会话。

这仍是站内 REST/WebSocket 通知，不代表 FCM/APNs 已接通。

## 7. Flutter 设计

### 7.1 社区双 Tab

`CommunityFeedScreen` 增加：

- `推荐`：继续调用公开 `/posts`。
- `关注`：登录用户调用 `/posts/following`。

游客切换到关注 Tab 时展示登录引导，不发起受保护请求。切换 CN/EU 时两个 Tab 均重新加载；推荐流和关注流都按当前区域取数。

### 7.2 公开用户主页

新增 `PublicUserProfileScreen` 和对应仓储模型：

- 展示头像、昵称、签名、等级、点评数、粉丝数、关注数。
- 登录用户查看他人时显示“关注/已关注”。
- 查看自己或游客查看他人时不显示可操作关注按钮；游客显示登录提示。
- 关注成功后立即更新按钮、`followedByCurrentUser` 和粉丝数，失败时恢复原状态并展示真实错误。
- 粉丝数与关注数进入分页关系列表，列表项可继续打开用户主页。

社区流、帖子详情和评论中的作者区域可以进入公开用户主页。

### 7.3 通知跳转

Flutter 通知页识别 `social.follow` 和 `/users/{id}`。点击时先确认已读，再进入关注者公开主页。无法解析的链接只确认已读，不制造错误跳转。

## 8. PC Web 设计

扩展现有公开用户主页：

- 展示粉丝数与关注数。
- 可只读进入粉丝和关注列表。
- 不展示关注、取关按钮。
- 社区列表与详情的作者名称链接到公开用户主页。

PC Web 继续承担只读内容与公开关系展示，不扩展社交写操作。

## 9. 隐私与注销治理

### 9.1 隐私导出

新增真实导出模块 `follows`，Web 与 Flutter 隐私中心默认选中。ZIP 中生成 `follows.json`：

```json
{
  "following": [
    {
      "userId": 9002,
      "nickname": "伦敦小王",
      "followedAt": "2026-07-16 12:00:00"
    }
  ],
  "followers": []
}
```

后端允许模块更新为 `account/reviews/orders/reservations/favorites/posts/follows`。未实现的 `messages` 仍不接受，也不生成空文件。

### 9.2 注销到期

注销到期处理：

- 删除 `follower_user_id = 当前用户` 的关系。
- 删除 `followed_user_id = 当前用户` 的关系。
- 删除当前用户收到的通知。
- 对 `actor_user_id = 当前用户` 的 `social.follow` 通知清空来源 ID，将内容改为“已注销用户曾关注了你”，并清空跳转链接。

处理完成后，其他用户粉丝数和关注数通过实时统计自然收敛，不需要异步修复缓存。

## 10. 错误处理与安全

- 关注自己返回 `400`，错误信息明确。
- 目标用户不存在、已注销或不可用时返回 `404`，不泄露额外状态。
- 未登录访问关注写接口或关注流返回 `401`。
- 重复关注和取关保持幂等成功。
- 唯一索引处理并发重复关注；服务不将数据库唯一冲突暴露给客户端。
- 粉丝/关注列表最多每页 50 条，页码小于 1 时归一化为 1。
- 关注流继续执行区域、审核、状态和删除过滤。
- 公开响应不返回邮箱、手机号或其他绑定账号信息。
- `GLOBAL` 仅用于通知数据，不扩展 `X-Region` 请求枚举；客户端请求头仍只允许 CN/EU。

## 11. 测试与验收

### 11.1 后端

- 未关注到关注、重复关注、取关和重复取关。
- 禁止关注自己，目标用户不存在或已注销。
- 粉丝数、关注数、公开粉丝列表和关注列表。
- 全局关注关系在 CN/EU 公开主页保持一致。
- 关注流只返回当前区域内审核通过的被关注者帖子。
- 首次关注生成一条 `GLOBAL` 通知，重复关注和取关不生成通知。
- `GLOBAL` 通知在 CN/EU 均可见，确认已读后两区一致。
- 区域业务通知查询行为不退化。
- `follows.json` 包含真实关系数据。
- 注销到期删除关系并治理来源通知。

### 11.2 Flutter

- 推荐/关注双 Tab 加载与切换。
- 游客关注 Tab 登录引导。
- 公开用户主页、关注按钮和即时计数更新。
- 粉丝/关注列表与用户主页跳转。
- 社区作者进入用户主页。
- `social.follow` 通知确认已读并跳转。

### 11.3 PC Web

- 公开用户主页展示粉丝数和关注数。
- 粉丝/关注列表只读展示。
- 页面不存在关注或取关操作。
- 社区作者链接指向公开用户主页。

### 11.4 全量验收

实现完成后运行：

```powershell
.\scripts\ci\verify-all.ps1 -IncludeFlutter
```

真实 FCM/APNs、私信和圈子继续保留为未完成项，文档不得描述为已接通。

