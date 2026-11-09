$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$currentStatusPath = Join-Path $repoRoot 'docs\当前已完成功能与SQL导入说明.md'
$requirementsPath = Join-Path $repoRoot 'docs\需求文档.md'
$readmePath = Join-Path $repoRoot 'README.md'
$testChecklistPath = Join-Path $repoRoot 'docs\测试清单与验收用例.md'
$euBaselinePath = Join-Path $repoRoot 'docs\EU预发发布基线.md'
$euLedgerPath = Join-Path $repoRoot 'docs\EU预发执行与验收台账.md'
$groupBuyDeliveryPath = Join-Path $repoRoot 'docs\拼团订单交易与灰度运营-2026-11-08.md'

$currentStatus = Get-Content -Raw -LiteralPath $currentStatusPath
$requirements = Get-Content -Raw -LiteralPath $requirementsPath
$readme = Get-Content -Raw -LiteralPath $readmePath
$testChecklist = Get-Content -Raw -LiteralPath $testChecklistPath
$euBaseline = Get-Content -Raw -LiteralPath $euBaselinePath
$euLedger = Get-Content -Raw -LiteralPath $euLedgerPath
$groupBuyDelivery = Get-Content -Raw -LiteralPath $groupBuyDeliveryPath

function Assert-Contains {
    param([string]$Text, [string]$Expected, [string]$Message)
    if (-not $Text.Contains($Expected)) {
        throw $Message
    }
}

function Assert-NotContains {
    param([string]$Text, [string]$Unexpected, [string]$Message)
    if ($Text.Contains($Unexpected)) {
        throw $Message
    }
}

Assert-Contains $currentStatus '## 2.2 全局功能完成矩阵' '缺少全局功能完成矩阵'
Assert-Contains $currentStatus '| 功能域 | 状态 | 已完成证据 | 剩余工作 | 完成判定 |' '功能矩阵列不完整'
Assert-Contains $currentStatus '商户端与管理端完整闭环' '缺少商户端与管理端缺口'
Assert-Contains $currentStatus 'PC Web 产品缺口' '缺少 PC Web 缺口'
Assert-Contains $currentStatus '社区与消息尾项' '缺少社区与消息缺口'
Assert-Contains $currentStatus 'Flutter 与真实第三方' '缺少 Flutter 与第三方缺口'
Assert-Contains $currentStatus '目标环境与上线执行' '缺少目标环境缺口'
Assert-NotContains $currentStatus '剩余未完成项是 M7 关系链/私信/圈子/真实推送' '关注、私信和圈子已完成，不能再次列为未完成'

Assert-Contains $requirements '当前实现与验收状态以 [`当前已完成功能与SQL导入说明.md`](当前已完成功能与SQL导入说明.md) §2.2、§5 为准' '需求文档未声明当前状态权威入口'
Assert-Contains $readme '全局功能完成矩阵' '根 README 未指向全局功能完成矩阵'
Assert-Contains $testChecklist '仓库全量本地基线已于 2026-07-18 重新验证通过' '测试清单没有本轮验证事实'

Assert-NotContains $euBaseline '拼团目前仍只有开团/参团状态' 'EU 基线仍把已完成的拼团交易写成组队状态'
Assert-NotContains $euLedger '拼团活动价订单、支付、发券、成团/超时退款及库存补偿仍未完成' 'EU 台账仍把拼团交易闭环写成未完成'
Assert-Contains $currentStatus '在线咨询已在用户 Web、商户端与 Flutter 接入最近 50 条消息、历史翻页与增量补收' '权威功能矩阵仍未同步咨询分页完成状态'
Assert-Contains $currentStatus '拼团现已接入独立成员订单' '权威功能矩阵仍未同步拼团交易完成状态'
Assert-Contains $euLedger 'GB-01' 'EU 台账缺少拼团目标环境验收场景'
Assert-Contains $euLedger '第 30 号迁移' 'EU 台账缺少拼团订单迁移回滚边界'
Assert-Contains $euLedger '第 31 号迁移' 'EU 台账缺少拼团灰度迁移回滚边界'
Assert-Contains $groupBuyDelivery '渠道明确返回失败时保留原交易状态' '拼团交付记录缺少终态退款失败边界'
Assert-Contains $groupBuyDelivery '迁移终点为 29' '拼团交付记录未阻断旧候选包口径'
Assert-Contains $groupBuyDelivery 'eu-pre-rc-20261108-2' '拼团交付记录缺少当前技术候选'
Assert-Contains $groupBuyDelivery '4ad66a0d3c806d8b455c877ec34fb92e1f55d832' '拼团交付记录未绑定当前不可变主干'
Assert-Contains $euLedger 'eu-pre-rc-20261108-2' 'EU 台账缺少当前技术候选'
Assert-Contains $euBaseline 'PR #36' 'EU 基线缺少终态退款人工核验交付状态'
Assert-NotContains $euLedger '补丁合入并取得同 SHA CI/nightly 后须使用新版本号生成候选' 'EU 台账仍把已生成的当前候选写成待生成'

Write-Output 'document status consistency contract passed'
