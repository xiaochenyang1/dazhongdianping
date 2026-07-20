# Document Status Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可自动校验的功能完成矩阵，消除当前文档对 M1-M7 和剩余缺口的互相矛盾描述。

**Architecture:** 继续使用 `docs/当前已完成功能与SQL导入说明.md` 作为实现状态权威入口，不新造第二份总览。通过 PowerShell 契约测试校验关键状态、日期、矩阵字段和已知矛盾句，`verify-all.ps1` 会自动发现该测试。

**Tech Stack:** Markdown、PowerShell 7、现有 `scripts/ci/verify-all.ps1` 契约测试机制

---

### Task 1: 为文档状态建立失败契约

**Files:**
- Create: `scripts/ci/test-doc-status-consistency.ps1`
- Test: `scripts/ci/test-doc-status-consistency.ps1`

- [x] **Step 1: 创建会因当前矛盾文档而失败的契约测试**

```powershell
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$currentStatusPath = Join-Path $repoRoot 'docs\当前已完成功能与SQL导入说明.md'
$requirementsPath = Join-Path $repoRoot 'docs\需求文档.md'
$readmePath = Join-Path $repoRoot 'README.md'
$testChecklistPath = Join-Path $repoRoot 'docs\测试清单与验收用例.md'

$currentStatus = Get-Content -Raw -LiteralPath $currentStatusPath
$requirements = Get-Content -Raw -LiteralPath $requirementsPath
$readme = Get-Content -Raw -LiteralPath $readmePath
$testChecklist = Get-Content -Raw -LiteralPath $testChecklistPath

function Assert-Contains {
    param([string]$Text, [string]$Expected, [string]$Message)
    if (-not $Text.Contains($Expected)) { throw $Message }
}

function Assert-NotContains {
    param([string]$Text, [string]$Unexpected, [string]$Message)
    if ($Text.Contains($Unexpected)) { throw $Message }
}

Assert-Contains $currentStatus '## 2.2 全局功能完成矩阵' '缺少全局功能完成矩阵'
Assert-Contains $currentStatus '| 功能域 | 状态 | 已完成证据 | 剩余工作 | 完成判定 |' '功能矩阵列不完整'
Assert-Contains $currentStatus '商户端与管理端完整闭环' '缺少商户端与管理端缺口'
Assert-Contains $currentStatus 'PC Web 产品缺口' '缺少 PC Web 缺口'
Assert-Contains $currentStatus '社区与消息尾项' '缺少社区与消息缺口'
Assert-Contains $currentStatus 'Flutter 与真实第三方' '缺少 Flutter 与第三方缺口'
Assert-Contains $currentStatus '目标环境与上线执行' '缺少目标环境缺口'
Assert-NotContains $currentStatus '剩余未完成项是 M7 关系链/私信/圈子/真实推送' '关注、私信和圈子已完成，不能再次列为未完成'

Assert-Contains $requirements '> 实现状态权威入口:`当前已完成功能与SQL导入说明.md` §2.2' '需求文档未声明状态权威入口'
Assert-Contains $readme '全局功能完成矩阵' '根 README 未指向全局功能完成矩阵'
Assert-Contains $testChecklist '仓库全量本地基线已于 2026-07-18 重新验证通过' '测试清单没有本轮验证事实'

Write-Output 'document status consistency contract passed'
```

- [x] **Step 2: 运行契约并确认失败**

Run:

```powershell
.\scripts\ci\test-doc-status-consistency.ps1
```

Expected: FAIL，错误至少包含 `缺少全局功能完成矩阵`。

### Task 2: 修正权威状态文档并加入完整矩阵

**Files:**
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Test: `scripts/ci/test-doc-status-consistency.ps1`

- [x] **Step 1: 修正 M7 自相矛盾描述**

将：

```markdown
- M5c/M5d、M6 与 M7 帖子第一阶段本地业务闭环已完成。剩余未完成项是 M7 关系链/私信/圈子/真实推送、真实第三方能力与真实外部环境凭证联调。
```

改为：

```markdown
- M1-M7 当前文档已声明的帖子、关注流、1v1 私信、官方圈子和话题热榜本地闭环均已完成。剩余仓库内缺口集中在商户/管理端前台补全、PC 产品细节、帖子转发、评论盖楼、@ 提醒、达人认证、完整国际化和真实第三方适配；真实环境凭证联调仍未完成。
```

- [x] **Step 2: 在 §2.1 后增加全局功能完成矩阵**

```markdown
## 2.2 全局功能完成矩阵

> 状态含义：`已完成` 表示实现、自动化和当前本地运行证据齐全；`部分完成` 表示已有主链路但仍有明确需求缺口；`外部待验收` 表示仓库入口已具备但缺少真实账号、凭证或目标环境结果。

| 功能域 | 状态 | 已完成证据 | 剩余工作 | 完成判定 |
|---|---|---|---|---|
| M1-M4 用户核心链路 | 已完成（本地口径） | 浏览、搜索、认证、点评、成长、榜单、收藏、交易和预订均有后端、Web 与自动化覆盖 | 真实支付归第三方阶段；预订到店提醒归消息阶段 | 当前自动化、浏览器 E2E 和目标数据库 smoke 全部通过 |
| M5 商户经营后端 | 已完成 | 入驻、员工 RBAC、门店范围、预订、团购、订单退款、门店草稿、点评回复申诉已落地 | 无后端主流程缺口 | 后端权限、状态机、跨商户和跨区域测试通过 |
| 商户端与管理端完整闭环 | 部分完成 | `merchant-web` 已有登录、看板、门店、预订、团购、退款和点评页面；管理端已有门店、审核、榜单、成长、圈子、话题 | 商户注册/资质/员工页面；管理端商户审核、管理员 RBAC、基础数据、用户、订单、运营活动和审计查询 | B/Admin 两端页面与后端权限 E2E 全部通过 |
| PC Web 产品缺口 | 部分完成 | 首页、列表、详情、搜索、交易、预订、用户中心和社区只读页已落地 | 高级筛选 UI、真实分页、点评排序、分享、相似推荐、预渲染 SEO | 对应组件测试、后端查询测试和浏览器 E2E 通过 |
| 社区与消息尾项 | 部分完成 | 帖子、关注流、私信、圈子、话题和基础通知已落地 | 帖子转发、评论盖楼、@ 提醒、赞评关私信通知聚合、达人认证 | 社交关系幂等、通知去重、隐私治理和 Flutter E2E 通过 |
| Flutter 与真实第三方 | 部分完成 | Flutter 具备区域切换、基础三语言入口、交易/社区/隐私主链路；未配置能力会诚实禁用 | 完整 i18n、点评翻译、Google Maps、Stripe/PayPal/支付宝/微信、FCM/APNs、邮件短信和内容审核 | 官方 sandbox、签名契约和真实凭证 smoke 均通过 |
| 目标环境与上线执行 | 外部待验收 | MySQL、Redis、S3、ES、发布回滚脚本及 CI workflow 已存在 | 真实云资源、域名证书、CDN、SSH、预算、联系人和供应商账号 | 上线清单与执行台账由有权限负责人填写，目标环境发布/回滚演练通过 |
```

- [x] **Step 3: 运行契约，确认权威文档部分已满足**

Run:

```powershell
.\scripts\ci\test-doc-status-consistency.ps1
```

Expected: 仍 FAIL，但错误应推进到需求文档、README 或测试清单同步项。

### Task 3: 同步需求、README 和测试证据

**Files:**
- Modify: `docs/需求文档.md`
- Modify: `README.md`
- Modify: `docs/测试清单与验收用例.md`
- Test: `scripts/ci/test-doc-status-consistency.ps1`

- [x] **Step 1: 在需求文档当前实现范围前声明权威入口**

在 `## 当前代码已落地范围` 下增加：

```markdown
> 实现状态权威入口:`当前已完成功能与SQL导入说明.md` §2.2。本文各功能章节中的复选框主要表达目标范围，不再单独作为完成判定，避免需求清单与代码状态各唱各的。
```

- [x] **Step 2: 在根 README 当前状态后增加矩阵入口**

```markdown
完整的“已完成 / 部分完成 / 外部待验收”证据请看 `docs/当前已完成功能与SQL导入说明.md` 的“全局功能完成矩阵”；根 README 只保留启动入口和阶段摘要，不再重复维护第二套完成判断。
```

- [x] **Step 3: 更新测试清单的本轮基线事实**

在 `## 1.1 当前自动化验证状态` 下增加：

```markdown
- 仓库全量本地基线已于 2026-07-18 重新验证通过：`scripts/ci/verify-all.ps1 -IncludeFlutter` 输出 `all requested checks passed`，覆盖脚本契约、后端、三个 Web 工程和 Flutter 测试/分析/构建。
- 该基线不包含目标环境 MySQL/Redis/S3/SSH、真实支付、Google Maps、FCM/APNs、短信邮件和内容审核凭证验收；这些能力继续标为未完成，不能拿本地绿灯冒充上线绿灯。
```

- [x] **Step 4: 运行文档一致性契约**

Run:

```powershell
.\scripts\ci\test-doc-status-consistency.ps1
```

Expected: PASS，输出 `document status consistency contract passed`。

### Task 4: 将契约纳入全量验证并做阶段验收

**Files:**
- Verify: `scripts/ci/verify-all.ps1`
- Verify: `scripts/ci/test-doc-status-consistency.ps1`
- Verify: `docs/当前已完成功能与SQL导入说明.md`

- [x] **Step 1: 验证 verify-all 会自动发现新契约**

Run:

```powershell
.\scripts\ci\verify-all.ps1 -DryRun
Get-ChildItem -LiteralPath .\scripts\ci -Filter 'test-*.ps1' | Sort-Object Name | Select-Object -ExpandProperty Name
```

Expected: 列表包含 `test-doc-status-consistency.ps1`；`verify-all.ps1` 的 `Invoke-CiContractTests` 会执行全部 `test-*.ps1`。

- [x] **Step 2: 运行所有脚本契约**

Run:

```powershell
Get-ChildItem -LiteralPath .\scripts\ci -Filter 'test-*.ps1' | Sort-Object Name | ForEach-Object { & $_.FullName; if ($LASTEXITCODE -ne 0) { throw "$($_.Name) failed" } }
```

Expected: 所有契约通过。

- [x] **Step 3: 检查文档不再包含已知矛盾**

Run:

```powershell
Select-String -LiteralPath .\docs\当前已完成功能与SQL导入说明.md -Pattern '剩余未完成项是 M7 关系链/私信/圈子/真实推送'
```

Expected: 无输出。

> 当前目录没有 `.git` 元数据，本阶段无法执行 commit。文件和测试结果作为阶段检查点；Git 基线恢复后再补正常提交历史。
