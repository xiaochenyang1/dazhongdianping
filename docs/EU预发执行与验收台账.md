# EU 预发执行与验收台账

更新时间：2026-11-13。首发范围沿用 [EU 基线](EU预发发布基线.md)：巴黎单城、EUR、`Europe/Paris`。本文件给出执行顺序和证据字段；空白验收项均为待执行，不能凭本地测试或配置门禁通过改为已验收。

## 1. 当前交付与环境边界

PR #28（创作者成果提交、人工审核与一次性发奖）已合入主干 `246d90b42190839476cbe24891e14242b83a83f0`，该 SHA 的 [CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42177650106) 已通过，[同 SHA nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42181027617) 的结论以运行页为准。候选包、迁移 28、默认关闭开关及包内 JAR 启动结果见 [创作者交付记录](创作者任务提交审核与发奖-2026-11-06.md#主干与技术候选)。

咨询消息分页与增量补收、咨询会话列表分页与未读筛选、工单追问和发票 PDF 私密交付均已进入主干。咨询会话列表及容量结果见 [开发记录](咨询会话列表分页与未读筛选-2026-11-06.md)。

PR #30（秒杀订单交易闭环）已合入主干 `24fba53e707ef73b086e70a69a60fc538026415b`。该 SHA 的 [CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42324586352) 与 [nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42325997994) 均通过，活动价订单、两层并发库存、支付发券、取消/到期释放、退款、迟到支付自动退款和券码核销已进入主干，配套迁移终点为 29；候选包及运行结果见 [秒杀交付记录](秒杀订单交易闭环-2026-11-06.md#主干与技术候选)。基础巴黎预发仍保持秒杀开关关闭，目标环境业务验收前不得开放。

PR #35 交付拼团订单交易与灰度运营，PR #36 进一步收口渠道终态退款失败的人工核验与本地幂等补齐；其合并主干 `4ad66a0d3c806d8b455c877ec34fb92e1f55d832` 的 [CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42465825993)、[手工 nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42467072287) 与 [定时 nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42526357580) 均通过。配套迁移终点为 31，默认 `group_buy` 总开关与范围规则均关闭；现有 03–31 技术候选及包内 JAR 启动结果见 [拼团交付记录](拼团订单交易与灰度运营-2026-11-08.md)。

隐私数据域收尾和团购标题搜索已合入主干，扫码交付见 [摄像头验证记录](商户摄像头扫码验证-2026-10-24.md)。隐私变更新增第 26 号迁移，既有 Elasticsearch 索引必须执行全量重建。最终发布版本以同一不可变 SHA 的 CI、nightly、候选 manifest 与 SHA-256 为准，执行结果保存在对应日期的候选记录中。

PR [#37](https://github.com/xiaochenyang1/dazhongdianping/pull/37) 已把手工 `test/EU` 重试入口、发布身份、WebSocket 真实来源和部署后验收证据合入主干；该能力的合并基线为 `e92ba3c228ccd5d7fb02f1e8969bb8ad82f8c982`，其 [主干 CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42574817291) 全部通过。后端 JAR 会编入版本、commit、构建环境/区域和迁移终点，公开只读 `/api/c/v1/release-info` 与管理端系统健康页展示该身份；发布/回滚会从远端 `current` manifest 交叉核对在线身份、actuator、延期功能关闭状态、WSS origin 和 HTTPS smoke，并上传脱敏 JSON/Markdown 报告。API 与 smoke URL 禁止 query/fragment；`test` 回滚固定使用 EU 和 `release-test-EU` 并发锁，非 EU 请求在 SSH 前拒绝；`VITE_WS_BASE_URL` 只接受 `wss://host[:port]` origin，前端自行追加 `/ws/notifications`。

PR [#46](https://github.com/xiaochenyang1/dazhongdianping/pull/46) 已把 Environment 自定义部署来源的明细审计合入主干 `f6de5f9862ff30367b7dd2ad7177fc57542bee96`。该提交的 [主干 CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42767544480) 全部通过，其中 MySQL 迁移集成耗时 55 秒，全量验证耗时 18 分 42 秒；`pre/test` 当前均只允许 `main` 分支和 `eu-pre-rc-*` 标签，部署来源门禁已通过最新脚本核对。

2026-11-10 对同一主干提交分别运行了只读的 [`pre/EU` readiness](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42769728523) 和 [`test/EU` readiness](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/42772204662)。两次报告都确认自动测试已就绪，但 Environment 均缺少 6 个公开变量和 7 个部署 secret，且无法取得目标机证据；`pre` 另缺 required reviewer，并仍允许管理员绕过。`prod` 尚未创建。报告均为 `readyForDeployment=false`、`mutatedExternalState=false`，没有输出主机、私有路径或凭证正文。目标机、HTTPS/WSS、数据库/中间件、Stripe test、SMTP/Twilio 配置尚未提供，因此当前仍不能打包环境化候选或执行真实部署。

PR #48–#53 已在 2026-11-13 前全部进入主干：签名 iOS IPA 流水线、nightly 咨询测试隔离、候选完整门禁、隔离 MySQL/Redis/MinIO/Elasticsearch 编排、只允许 `test/EU` 且核对在线发布身份的远端浏览器验收，以及同 ref、同 SHA 的手工发布来源门禁和打包前目标机只读预检均已落库。最新冻结源码候选 `eu-pre-rc-20261113-2` 指向 `dc7d0ff8cfe770c2f2fc020dbe72449321240336`；其 [主干 CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43395962901)、[nightly](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43398489069) 与 [tag CI](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43399956525) 均通过。

2026-11-13 再次只读检查 GitHub Environment：`test` 仍为 0 variables / 0 secrets，按当前契约缺 10 个 variables 和 11 个 secrets；`pre` 仍只有 6 个非敏感固定 variables / 0 secrets，缺 6 个 variables、7 个 secrets 和 required reviewer，并允许管理员绕过；`prod` 不存在。当前 SHA 尚未取得 `readyForDeployment=true` 报告，也没有环境化 ZIP、真实目标机预检、部署后验收或远端浏览器验收证据。

同日曾对上一候选 `eu-pre-rc-20261113-1` 执行 [`test/EU` readiness](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43387040998)。该历史报告精确绑定 `c0720f877c2ee9d36c6c8ad7fb19afd534f75576`：自动测试门禁为通过，GitHub Environment 当时缺 6 个必需变量和 7 个部署 secret，目标机证据无法采集，最终 `readyForDeployment=false`、`mutatedExternalState=false`。

该旧运行早于手工 `test/EU` 发布接入远端浏览器验收。当前仓库已把四个验收 HTTPS origin 和四个管理员/商户凭据纳入 test Environment 预检，并在部署后自动执行 13 条用例。新的 [`test/EU` readiness](https://github.com/xiaochenyang1/dazhongdianping/actions/runs/43403449494) 已绑定 `dc7d0ff8cfe770c2f2fc020dbe72449321240336` 重跑：CI ready，Environment 按新契约缺 10 个变量和 11 个 secret，目标机证据无法采集，`readyForDeployment=false`、`mutatedExternalState=false`；脱敏 JSON/Markdown 已作为 30 天 artifact 上传。配置补齐后须再次生成 readiness，再手工发布 test 并归档浏览器验收 artifact。

## 2. 开始部署前的输入

| 输入 | 存放位置 / 完成条件 | 当前状态 |
| --- | --- | --- |
| 版本与制品 | 固定 SHA/tag，CI 与 nightly 链接，ZIP、SHA-256、manifest | 当前源码候选 `eu-pre-rc-20261113-2` 绑定 `dc7d0ff…`，同 SHA 主干 CI、nightly 与 tag CI 已通过；源码门禁已用真实 Actions 数据确认 tag CI `43399956525` 的两个必需 job 成功，但尚无环境化 ZIP/manifest。历史技术包 `eu-pre-rc-20261108-2` 仅作旧基线证据，不能部署；真实配置补齐后须使用版本号唯一的环境化候选，不得改写现有标签 |
| 目标机与发布服务 | `test` / `pre` SSH、发布根目录、四个服务、HTTPS smoke URL | 待提供 |
| 数据库 | 私有 MySQL defaults 文件权限 `0400/0600`；迁移模式与已有库准确基线 | 待提供 |
| 运行环境 | 私有 env 文件或密钥管理引用；严格 `pre`、Redis、S3、ES、CORS/可信代理 | 待提供 |
| 支付 | Stripe test 账户、publishable key、服务端 key、Webhook endpoint/signing secret | 待提供 |
| 验证码 | 可验收 SMTP 发信账号/域名、Twilio 服务、测试邮箱和欧洲手机号 | 待提供 |
| 商户与运营 | 巴黎真实门店、商户/员工账号、EUR 套餐、合规图片、可订时段、客服/发票交付流程 | 待提供 |
| 恢复与值班 | 备份位置、恢复目标、可回滚版本、告警接收人和执行负责人 | 待提供 |

具体变量和模式约束沿用 [环境配置清单](EU预发环境配置清单.md) 与 [`deploy/eu-pre.env.example`](../deploy/eu-pre.env.example)。台账只记录配置文件路径、密钥管理引用和业务 ID，不记录密钥、完整验证码、完整电话、个人导出 ZIP 或原始支付报文。

## 3. 执行顺序

1. 在目标环境核对运行与 GitHub Environment 配置，加载私有 env 后执行预检。发布 workflow 会在打包前再次运行目标机只读预检；预检通过只证明配置、权限与入口连通性，真实送达和支付仍按下一节验收。

   ```bash
   set -a
   source /path/to/private/eu-pre.env
   set +a
   ./scripts/ci/stripe-preflight.sh --check-cli
   ```

2. 在已通过 CI 的固定 SHA 干净工作区用真实构建配置打包，调用 `scripts/ci/package-release.ps1 -Version <新版本> -CommitSha <40位SHA>`，或设置 `APP_RELEASE_COMMIT_SHA`。脚本以实际 Git HEAD 为来源并校验显式 SHA，拒绝未提交改动、未跟踪构建输入和已有版本输出，不使用 `GITHUB_SHA` 冒充源码来源。核对包内后端 JAR、三端 dist、03–31 连续迁移与全部校验和、迁移 runner；manifest 的 SHA、EU 默认区域、API/WSS、Stripe 和实际 SEO 快照必须一致。配置变化重新生成新版本。
3. 在独立恢复环境完成数据库备份恢复核对，记录数据一致性、迁移版本和恢复耗时。确认已有库的基线再应用迁移；不要把历史基线直接假设为 25，也不要把全量 schema/seed 导入现有库。仓库的 `mysql-smoke.ps1`、ES smoke 和浏览器 E2E 面向隔离测试，不能直接当作现有预发库的部署命令。
4. 先部署 `test`，再部署 `pre`。配置补齐后可在 release workflow 选择 `test`，从已通过 CI 的固定 ref 手工重试；test 固定 EU，所选 ref 的 `github.sha` 必须与构建和部署预期 SHA 一致，配置不完整时手工运行应失败。也可使用 `deploy-release.ps1 -ExpectedCommitSha <已验证的40位SHA>`（或设置 `DEPLOY_EXPECTED_COMMIT_SHA`），其公共预检在 SSH/SCP 之前校验 ZIP/旁车、源码、版本、环境/区域、迁移与 Web/Stripe/SEO 配置。技术候选仅能通过 `release-bundle-preflight.ps1 -ArtifactOnly` 的制品检查，不能直接部署。正式执行还必须得到 `post-deploy-acceptance.ps1` 的报告：远端 manifest、在线 release-info、actuator、延期功能关闭状态和 HTTPS smoke 全部匹配；失败报告保留证据并触发既有自动恢复。`-DryRun` 仅展示计划，不验证实际包或连接目标机。自动入口因配置门禁导致步骤 skipped 仍记为未部署。
5. ES 目标索引执行管理员 `POST /api/admin/v1/search/reindex`，等待队列清空，核对失败任务为零，再测试中文/英文团购标题、编辑旧词移除、上下架、审核和区域隔离。不能用 H2/MySQL 搜索通过替代已有 ES 索引重建。
6. 在真实供应商和目标环境按下表执行交易、预订、隐私和商户试用；保存合成订单/券/退款 ID、供应商事件 ID、状态核对和截图。验收过程不操作真实消费者资金或个人记录。
7. 在 `test` 和 `pre` 分别演练应用回滚及同组 HTTPS smoke，确认当前/previous/旧版本保留策略和告警处置；最后由业务、运维和隐私责任人填验收结论。

## 4. 验收记录表

每行补充执行日期、负责人、目标环境、版本 SHA、证据链接与结果（通过 / 失败 / 待执行）；只满足本地自动化条件的项保留为待目标环境验收。

| ID | 场景与通过标准 | 需留存证据 | 当前结果 |
| --- | --- | --- | --- |
| INF-01 | HTTPS/WSS、显式 CORS、可信代理与后端不可绕过代理直连；MySQL/Redis/S3/ES 可用 | 拓扑确认、健康/连接与代理隔离结果 | 待执行 |
| OTP-01 | 真实邮箱收到验证码并注册/登录；不回显验证码 | 邮件服务事件 ID、送达时间、合成账号 ID | 待执行 |
| OTP-02 | 欧洲手机号真实收码；无匹配渠道仍 `503`，不跨通道回退 | Twilio 消息 ID、送达状态与号码区域 | 待执行 |
| PAY-01 | EUR 下单、Stripe test 支付及 3DS、有效 Webhook 验签、只发一次券 | 订单/PaymentIntent/event/券 ID 与金额状态 | 待执行 |
| PAY-02 | 非法签名返回 `400`；严格预发 EU 订单无法 mock-complete；重复回调幂等 | HTTP 结果、前后订单/券计数 | 待执行 |
| REF-01 | 未使用券退款审批、失败保持原状态、异步补偿、Stripe 回执与 CSV 账单匹配 | refund ID、渠道状态、库存与账单差异 | 待执行 |
| GB-01 | 在独立功能验收配置中完成开团/参团、全员付款成团发券、混合已付/未付到期、自动退款、库存释放、截止提醒和灰度命中；渠道明确失败不得自动重提，后台须准确告警。分别验证“渠道未退款”保留失败与告警、“渠道已退款”不调用退款 API 且幂等补齐订单/券/库存/通知，并确认管理员区域、城市和门店范围隔离 | team/order/refund/coupon ID、Stripe 事件与核验编号、库存前后值、开关规则、通知与后台审计记录 | 待执行 |
| QR-01 | Android Chrome / iPhone Safari 实体相机识别，确认前不核销、重复核销拒绝 | 机型/浏览器、合成券 ID、请求与资源释放结果 | 待执行 |
| QR-02 | 拒绝授权仍可输码；页面隐藏/离开释放相机；错商户/门店/区域、过期/退款券拒绝 | 员工/门店范围、HTTP 结果、现场记录 | 待执行 |
| RSV-01 | 巴黎门店预订、确认、改期、取消及容量；当地时间与 DST 边界 | 预订 ID、时区快照、容量前后值 | 待执行 |
| ACL-01 | 用户/商户/管理员区域与门店范围隔离，员工停用/撤权及时失效 | 合成账号角色、脱敏 HTTP 与审计结果 | 待执行 |
| SRCH-01 | 重建后中文/英文标题命中；改名旧标题消失；非公开和错区不可见 | 索引名、重建任务与队列结果、查询截图 | 待执行 |
| PRIV-01 | 24 模块导出、本人/区域隔离、注销冷静期与到期清理、新旧任务补清理 | 合成账号/任务 ID、域计数、版本标记、归档清理结果 | 待执行 |
| PRIV-02 | 交易凭证最小留存、供应商/对象存储/日志/备份留存与恢复后删除处理被责任人确认 | 批准的留存表与恢复处理步骤 | 待执行 |
| BIZ-01 | 商户完成套餐/审核/上下架/预订/核销/退款试用，驳回与客服流程可操作 | 试用人员、业务 ID、问题与复验记录 | 待执行 |
| INV-01 | 实际开票责任明确，上传已开具 PDF、本人鉴权下载、客户显式确认收件的流程通过 | 交付负责人、脱敏凭证与发送/接收记录 | 待执行 |
| OPS-01 | 支付、隐私、搜索失败和验证码送达告警可触达，负责人完成一次处置 | 告警事件、接收与处置时间、联系表 | 待执行 |
| OPS-02 | 巴黎核心查询/下单/预订容量验证，业务约定并记录延迟和错误率阈值 | 数据规模、并发、目标阈值与实测结果 | 待执行 |
| DR-01 | 独立恢复环境从备份恢复，业务金额/券/预订一致，记录 RPO/RTO | 备份校验、恢复耗时、数据核对与删除再处理结果 | 待执行 |
| DR-02 | `test` 与 `pre` 各完成部署/回滚；同组 HTTPS smoke 均 `2xx` | 两环境发布与回滚 run、版本和 URL 结果 | 待执行 |

## 5. 迁移、删除与回滚边界

应用回滚脚本只切换应用版本并重启服务，不自动逆转数据库迁移，也不会恢复已经清理的个人数据或物理删除的隐私归档。第 26 号迁移带来历史任务补清理；回滚版本须确认兼容当前 schema，并评估旧版隐私行为，不能只依据能启动决定放行。

第 28 号迁移冻结创作者领取条款，并保留历史已发奖状态和原积分金额。回滚到仍支持旧 `/complete` 自助发奖的后端前，必须先关闭延期功能总开关；不得通过删除已发奖成果或积分流水来重置状态。

第 29 号迁移为订单增加活动来源、秒杀快照与一次性库存释放标记，并把参与记录关联到订单。回滚到不识别这些字段的旧后端前必须保持秒杀开关关闭；数据库迁移不会自动回退，也不得通过修改参与记录重新开放已付款用户的限购名额。

第 30 号迁移把拼团成员关联到独立订单，增加已付款人数与到期扫描索引；历史成员只保留为历史参与，不补订单、不补券。第 31 号迁移新增拼团提醒去重字段及活动/门店/城市灰度规则，并写入 CN/EU 默认关闭的 `group_buy` 总开关。回滚到不识别这些字段或仍使用旧组队语义的后端前，必须同时关闭部署总开关和数据库 `group_buy` 开关；不得删除订单/退款或改写成员状态来“回退”资金与库存。应用回滚不会逆转 30、31 号迁移，旧后端须先证明兼容当前 schema。

数据库备份恢复与应用回滚分开演练。恢复到较早备份可能重新带入已删除账号及个人数据，恢复后必须先核对已完成删除请求、重新执行批准的删除处理并验证归档/凭证保留边界，再开放流量。备份留存、可恢复窗口和删除记录的保存方式由隐私与运维负责人确认；当前本地事务回滚测试不证明这些实际操作已完成。

## 6. 延期事项保留

创作者成果关联、人工审核、驳回重提与一次性发奖，秒杀交易闭环，以及拼团订单、成团履约、到期退款、运营补偿和灰度控制均已完成源码与隔离自动化验证，并已有各自合入后主干 CI/nightly 证据。作品质量仍由审核员判断，已发奖后的内容修改或删除不会自动扣回积分；渠道明确失败的拼团退款须核对供应商流水并人工处置。三项延期能力的目标环境业务验收与开放仍延期。其他支付/币种、移动签名分发、地图/推送真机、自动翻译/第三方机审、稳定用户实验分组、社区个性化推荐、通用消息外部投递、常驻 SSR/域名 CDN 与商店发行继续按 [完整功能矩阵](当前已完成功能与SQL导入说明.md) 单独验收。部署总开关和三个 EU 延期开关保持 `false`，数据库 `group_buy` 规则也保持关闭。这些事项不因候选发布或巴黎基础链路通过而自动完成。
