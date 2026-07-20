# M7 私信闭环设计

## 目标

实现 APP 端登录用户之间的 1v1 文本私信，覆盖会话列表、消息分页、发送、已读、举报、拉黑、WebSocket 实时通知、隐私导出和注销治理。PC Web 不提供私信入口。

## 边界

- 仅文本消息，长度 1-2000；不做图片、文件、语音、群聊、红包或撤回。
- 会话是全局用户关系，不按 CN/EU 拆分；消息不携带业务区域。
- 拉黑是单向关系：任一方拉黑对方后，双方均不能在该会话继续发送。
- 举报支持消息和整段会话，举报后不自动删除原消息，由管理流程后续处理。
- 实时能力复用现有 WebSocket；FCM/APNs 仍不属于本阶段。

## 数据模型

- `conversation(id,user_a,user_b,last_message_id,last_message_preview,last_message_at,created_at,updated_at)`，用户对排序后唯一。
- `message(id,conversation_id,from_user_id,to_user_id,content,is_read,read_at,status,is_deleted,created_at)`。
- `user_block(id,user_id,blocked_user_id,created_at)`，唯一键禁止重复。
- `message_report(id,reporter_user_id,target_type,target_id,reason,status,created_at)`，`target_type=1` 消息、`2` 会话。

## API

- `GET /api/c/v1/messages/conversations`
- `GET /api/c/v1/messages/conversations/{id}`
- `POST /api/c/v1/messages/send`
- `POST /api/c/v1/messages/conversations/{id}/read`
- `PUT /api/c/v1/messages/blocks/{userId}`
- `DELETE /api/c/v1/messages/blocks/{userId}`
- `GET /api/c/v1/messages/blocks`
- `POST /api/c/v1/messages/report`

发送请求使用 `toUserId/content`。首次发送原子创建会话；并发重复创建依赖用户对唯一键归一化。禁止给自己、不可用用户或存在任一方向拉黑关系的用户发消息。

## 实时通知

发送事务提交后，通过指定用户全部区域 WebSocket 会话发送 `message.new`，负载包含会话 ID、消息摘要、发送者与创建时间。REST 会话列表和消息分页负责离线补偿。

## Flutter

- 公开用户主页增加“发私信”入口，仅登录且非本人可见。
- 会话列表显示对端、最后消息、时间和未读数。
- 聊天页分页展示双方消息，进入页面确认已读；发送失败保留输入并展示真实错误。
- 会话页提供举报与拉黑；拉黑后输入区禁用，可解除拉黑。

## 隐私与注销

- 隐私导出开放 `messages`，包含参与会话和本人发送/接收的消息。
- 注销到期删除拉黑关系；本人消息保留会话完整性但发送者显示为已注销用户、内容替换为“消息已因账号注销移除”；删除本人收到的未读状态与举报身份关联。

## 测试

- 会话幂等创建、发送、分页、未读和已读。
- 自发消息、目标不存在、双向拉黑阻断、重复拉黑/解除。
- 举报消息/会话与重复举报。
- WebSocket 提交后发送。
- `messages` 隐私导出和注销治理。
- Flutter 会话列表、聊天、发送、已读、举报、拉黑和公开主页入口。

