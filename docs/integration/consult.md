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

用户 Web、商户端与 Flutter 已一起适配。后端与三个客户端须配套发布：旧客户端没有消息历史翻页入口，且会话列表的响应已从数组改为下面的分页对象。

验证入口：后端 `ConsultLifecycleControllerTest`，三端咨询测试，`web/e2e/real-backend-flow.spec.ts`，以及隔离 MySQL 的 `scripts/ci/mysql-smoke.ps1`。

MySQL smoke 在本次创建的临时库中构造 10,001 条消息，通过 `consult-capacity-smoke.ps1` 混合验证用户/商户的最近页、历史页和空增量查询：10 个并发请求、20 轮、共 200 次，错误率要求 0、每页不超过 50 条、空增量返回 0 条、p95 小于 1,500 ms；另验双端并发发送后的增量完整性。计时包含响应等待和完成结果处理，作为可重复的 CI 基线，不能替代真实预发并发用户数、数据规模与延迟目标。输出写入该 smoke 临时目录的 `consult-capacity.json`。

**会话列表分页与未读筛选**

`GET /sessions` 返回 `list/hasMore/nextBeforeUpdatedAt/nextBeforeId`。默认 20 条，`pageSize` 范围为 1–100；不执行总数查询。

| 参数 | 含义 |
| --- | --- |
| 不传游标 | 最近活动的一页，按 `updated_at DESC, id DESC` 排序 |
| `beforeUpdatedAt` + `beforeId` | 必须成对提供；原样传回上一页的两个 `nextBefore*` 字段。时间使用服务端返回的无时区 ISO 时间串，ID 为正整数 |
| `unreadOnly=true` | 只返回当前阅读方未读数大于 0 的会话，默认为 false |
| `pageSize` | 默认 20，最大 100；无效大小或不完整/无效游标返回 400 |

```json
{
  "list": [{ "id": 25, "shopName": "示例门店", "unread": 2 }],
  "hasMore": true,
  "nextBeforeUpdatedAt": "2026-11-06T10:00:00",
  "nextBeforeId": 25
}
```

仅在 `hasMore=true` 时返回下一页游标；末页和空页的两个游标均为 null。商户列表在数据库中先应用商户、区域、员工门店范围及未读条件，再进行分页；没有权限范围的员工返回空页。列表读取本身不会标记已读，详情读取也不会改变活动时间。显式保留 `updated_at` 以避免 MySQL 的 `ON UPDATE` 在清零未读数时重排会话。

这是实时列表的边界分页，不是冻结快照。两次翻页之间有新消息时，会话可能移动到最新页；刷新回到第一页可看到移动的会话。静态数据保证同一时间戳下无重复/遗漏，不承诺并发变动时跨页总数恒定。三个客户端使用上一页/下一页；改变筛选从第一页开始，失败保留当前页，旧响应不会覆盖新筛选。商户每 3 秒刷新当前页，选中的会话与列表分开保存，翻页、筛选或会话标成已读后仍保留消息和草稿；线程读取失败时暂停发送，重试恢复后继续。

继续使用既有 `(user_id,region,updated_at)` 与 `(merchant_id,region,updated_at)` 索引（MySQL InnoDB 索引叶子包含主键），无需新增迁移，终点仍为 27。未读和多门店范围是额外过滤条件，可能扫描多条候选记录；下面的稀疏未读场景提供受控验证，不代表所有数据分布的性能保证。

`consult-session-capacity-smoke.ps1` 已接入隔离 MySQL smoke：构造 10,000 个合成用户、100 家合成门店；对该测试用户的 101 条会话和商户的 10,102 条会话逐页遍历并核对数据库总数、顺序与唯一 ID；另以 10 并发、200 次请求混合读取首页、后页及稀疏未读页。阈值为 0 错误、每页最多 20 条、p95 小于 1,500 ms。测试后移除合成数据，整个临时库在 smoke 结束时删除。这是本地/CI 基线，目标环境容量仍须独立验收。
