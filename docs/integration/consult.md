**在线咨询消息分页契约（2026-11-06）**

用户端与商户端分别使用 `/api/c/v1/consult`、`/api/b/v1/consult`，区域来自 `X-Region`。用户只能访问本人会话；商户列表、读取和回复同时受商户归属、区域和员工门店范围约束。读权限为 `consult:view`，回复权限为 `consult:reply`。

`GET /sessions/{id}/messages` 现在采用消息 ID 游标，默认返回最近 50 条，返回的消息始终按 ID 升序排列。

| 参数 | 含义 |
| --- | --- |
| 不传游标 | 读取最近一页；`hasMore` 表示还有更早历史 |
| `beforeId` | 正整数；读取 ID 小于它的最近一页历史，`hasMore` 表示还有更早历史 |
| `afterId` | 非负整数；读取 ID 大于它的最早一页新增消息，`hasMore` 表示还需继续补收 |
| `pageSize` | 1–100，默认 50；越界返回 400 |

`beforeId` 和 `afterId` 不能同时使用；负游标、零 `beforeId` 返回 400。无权访问的用户、商户或门店返回 404；商户身份所属区域不匹配时由既有拦截器返回 403。

响应保留原有 `session` 和 `messages`，增加分页字段：

```json
{
  "session": { "id": 5, "unread": 0 },
  "messages": [{ "id": 101, "content": "示例消息" }],
  "hasMore": false,
  "nextBeforeId": 101,
  "nextAfterId": 101
}
```

消息仍有原有 `sessionId/senderType/senderId/content/createdAt` 字段。空页的 `nextBeforeId` 为 null，`nextAfterId` 保持传入的 `afterId`，无游标且空会话时为 0。

客户端必须分别保存历史游标和增量游标：

1. 首次读取最近一页，保存 `nextBeforeId`、`nextAfterId`，用 `hasMore` 决定是否显示“查看更早消息”。
2. 历史页用 `beforeId=nextBeforeId`，仅更新历史游标和历史按钮，不改变增量游标；按消息 ID 去重合并。
3. 轮询用 `afterId=nextAfterId`，每页成功后推进该游标；`hasMore=true` 时继续补收。当前三个客户端每轮最多补收 5 页，余量留到下一轮，避免持续流量占用无限请求。
4. 发送成功只合并已发送消息，**不得用发送响应的 ID 推进增量游标**，否则会漏掉上次读取后、发送前到达的对方消息。
5. 单页失败保留已收到的消息、草稿和最后成功游标；切换会话/区域忽略旧请求返回。后台暂停轮询，回前台继续补收。

历史翻页不会把新消息标成已读。最近一页读取沿用打开会话后清零的行为；增量补收只在非空末页清零，补收中途保留未读。空增量请求不会凭客户端传入的任意游标清掉未读。

同一会话的发送和读取在短事务中锁住会话行，发送先加锁再分配消息 ID，防止后提交的小 ID 被已推进的游标漏掉。服务事务使用 READ COMMITTED，确保等待行锁后读到最新已提交数据。查询使用既有 `(session_id,id)` 索引，并只取 `pageSize+1` 条判断余量，不遍历全部历史、不执行总数查询。本轮不新增 SQL 迁移，当前迁移终点仍为 27。

用户 Web、商户端与 Flutter 已一起适配。旧客户端虽能解析保留字段，但不会主动翻历史，因此必须与后端配套发布；不要用字段兼容代替产品行为验收。会话列表自身仍沿用原有列表接口，尚未分页，本轮容量结论只适用于单会话消息读取。

验证入口：后端 `ConsultLifecycleControllerTest`，三端咨询测试，`web/e2e/real-backend-flow.spec.ts`，以及隔离 MySQL 的 `scripts/ci/mysql-smoke.ps1`。

MySQL smoke 在本次创建的临时库中构造 10,001 条消息，通过 `consult-capacity-smoke.ps1` 混合验证用户/商户的最近页、历史页和空增量查询：10 个并发请求、20 轮、共 200 次，错误率要求 0、每页不超过 50 条、空增量返回 0 条、p95 小于 1,500 ms；另验双端并发发送后的增量完整性。计时包含响应等待和完成结果处理，作为可重复的 CI 基线，不能替代真实预发并发用户数、数据规模与延迟目标。输出写入该 smoke 临时目录的 `consult-capacity.json`。
