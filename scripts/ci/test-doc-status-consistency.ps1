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

Assert-Contains $requirements '> 实现状态权威入口:`当前已完成功能与SQL导入说明.md` §2.2' '需求文档未声明状态权威入口'
Assert-Contains $readme '全局功能完成矩阵' '根 README 未指向全局功能完成矩阵'
Assert-Contains $testChecklist '仓库全量本地基线已于 2026-07-18 重新验证通过' '测试清单没有本轮验证事实'

Write-Output 'document status consistency contract passed'
