# 客服工单与开放平台

区域取请求头 `X-Region`（缺省 CN）。开放读接口除外：验签通过后使用 `open_app.region`，不信任客户端 `X-Region`。

## 客服工单

表：`support_ticket`、`ticket_message`。

- 请求方 `requester_type`：1 用户，2 商家。商家工单的 `requester_id` 是商户 id，不是操作员 id。
- 发送方 `sender_type`：1 用户，2 商家，3 管理员。
- 状态 `status`：1 待处理，2 处理中，3 已解决，4 已关闭。

创建工单时会同时写入一条与正文相同的 `ticket_message`。用户和商家只能在状态为 1 或 2 时继续回复。管理员回复的发送方为 3；若原状态为 1，则改为 2。

### C 端（用户登录）

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/c/v1/tickets` | body `{subject, content, shopId?}`，`shopId` 默认 0。`messageKey=ticket.created` |
| GET | `/api/c/v1/tickets` | 仅当前用户的工单，分页 |
| GET | `/api/c/v1/tickets/{id}` | 含 `messages`；不是本人返回 404 |
| POST | `/api/c/v1/tickets/{id}/messages` | body `{content}`，仅状态 1 或 2 |

### 商家端（商户登录）

权限：列表 `ticket:view`，创建和回复 `ticket:reply`。`shopId` 必须属于当前商户。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/b/v1/tickets` | body `{subject, content, shopId}`。`messageKey=merchant.ticket_created` |
| GET | `/api/b/v1/tickets` | 当前商户发起的工单 |
| POST | `/api/b/v1/tickets/{id}/messages` | body `{content}` |

### 平台端（管理员登录）

读 `support:ticket:read`，写 `support:ticket:write`。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/api/admin/v1/tickets?status=&page=&pageSize=` | 当前区域工单 |
| GET | `/api/admin/v1/tickets/{id}` | 含 `messages` |
| POST | `/api/admin/v1/tickets/{id}/reply` | body `{content}`，`sender_type=3`；状态 1 时改为 2 |
| POST | `/api/admin/v1/tickets/{id}/status` | body `{status}`，只接受 2、3、4。`messageKey=admin.ticket_updated` |

## 开放平台

表：`open_app`、`open_api_key`。`secret_hash` 是内部密钥库，保存创建时返回的原始 secret，不做哈希，供 HMAC 校验。列表接口不返回 secret。

### 平台管理

读 `openapi:read`，写 `openapi:write`。应用区域为管理员当前 `X-Region`。

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/api/admin/v1/openapi/apps` | body `{name, ownerMerchantId}`。创建 status=1 的应用和一把密钥。响应含 `keyId` 与 `secret`，只此一次。`messageKey=admin.openapi_app_created` |
| GET | `/api/admin/v1/openapi/apps` | 应用列表及 `keyIds`，不含 secret |
| POST | `/api/admin/v1/openapi/apps/{id}/status` | body `{status}`。1 为启用，其他值停用 |

### 公开只读

`GET /api/open/v1/shops?limit=`

`GET /api/open/v1/reviews?shopId=&limit=`

不使用用户 JWT。`limit` 取值 1–20，默认 10。门店返回当前应用区域内 `status=1` 且未删除的记录：`id`、`name`、`address`、`score`。点评只返回 `audit_status=1`、`status=1` 且未删除的公开点评：`id`、`shopId`、`score`、`content`。`shopId` 可选，小于 1 返回 400。区域取已验签应用，忽略客户端 `X-Region`。

请求头：

- `X-Open-Key`：keyId
- `X-Open-Timestamp`：Unix 毫秒时间戳，与服务器相差超过 5 分钟则拒绝
- `X-Open-Signature`：小写十六进制签名

密钥缺失或停用、应用停用、时间戳超窗、签名不一致，均返回 401。

## HMAC 规范串

四段用换行符 `\n`（LF）连接。`METHOD` 大写。`path` 只含路径，不含 query、不含域名。

```
{keyId}\n{timestamp}\n{METHOD}\n{path}
```

示例（查询门店或点评，即使请求带 query，path 仍不含 query）：

```
ak0123abc...\n1710000000000\nGET\n/api/open/v1/shops
ak0123abc...\n1710000000000\nGET\n/api/open/v1/reviews
```

签名：

```
lowercase_hex(HMAC_SHA256(key = UTF-8(rawSecret), message = UTF-8(canonical)))
```

`rawSecret` 是创建应用时响应里的 `secret` 字符串本身，按 UTF-8 作为 HMAC 密钥，不要先做 hex 解码。
