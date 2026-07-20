$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\verify-all.ps1"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/verify-all.ps1 must exist"

$dryRunOutput = & $scriptPath -DryRun
$dryRunText = $dryRunOutput -join "`n"

Assert-True ($dryRunText -match "backend.*mvnw.cmd test") "dry-run output must mention backend tests"
Assert-True ($dryRunText -match "web.*npm test") "dry-run output must mention web tests"
Assert-True ($dryRunText -match "web.*npm run build") "dry-run output must mention web build"
Assert-True ($dryRunText -match "admin-web.*npm test") "dry-run output must mention admin-web tests"
Assert-True ($dryRunText -match "admin-web.*npm run build") "dry-run output must mention admin-web build"
Assert-True ($dryRunText -match "merchant-web.*npm test") "dry-run output must mention merchant-web tests"
Assert-True ($dryRunText -match "merchant-web.*npm run build") "dry-run output must mention merchant-web build"
Assert-True ($dryRunText -match "app.*flutter test") "dry-run output must mention optional Flutter tests"
Assert-True ($dryRunText -match "app.*flutter analyze") "dry-run output must mention optional Flutter analyze"
Assert-True ($dryRunText -match "app.*flutter build web") "dry-run output must mention optional Flutter web build"
Assert-True ($dryRunText -match "scripts/ci/test-.*\.ps1") "dry-run output must mention script contract tests"
Assert-True ($dryRunText -match "mysql-smoke.ps1") "dry-run output must mention optional MySQL smoke"
Assert-True ($dryRunText -match "storage-smoke.ps1") "dry-run output must mention optional storage smoke"
Assert-True ($dryRunText -match "browser-smoke.ps1") "dry-run output must mention optional browser smoke"
Assert-True ($dryRunText -match "browser-e2e.ps1") "dry-run output must mention optional browser E2E"
Assert-True ($dryRunText -match "elasticsearch-smoke.ps1") "dry-run output must mention optional Elasticsearch smoke"

Write-Host "verify-all script contract passed"
