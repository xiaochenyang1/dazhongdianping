$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowDir = Join-Path $repoRoot ".github\workflows"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$workflowFiles = Get-ChildItem -LiteralPath $workflowDir -File |
    Where-Object { $_.Extension -in @(".yml", ".yaml") }
Assert-True ($workflowFiles.Count -gt 0) "no GitHub workflow files were found"

$workflowText = ($workflowFiles |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"

Assert-True ($workflowText -notmatch 'actions/(checkout|setup-java|setup-node)@v4') "workflows must not use deprecated Node.js 20 action majors"
Assert-True ($workflowText -match 'actions/checkout@v5') "workflows must use checkout v5"
Assert-True ($workflowText -match 'actions/setup-java@v5') "workflows must use setup-java v5"
Assert-True ($workflowText -match 'actions/setup-node@v5') "workflows must use setup-node v5"

Write-Output "GitHub action runtime contract passed"
