$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowPath = Join-Path $repoRoot ".github\workflows\nightly.yml"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $workflowPath) ".github/workflows/nightly.yml must exist"

$workflow = Get-Content -LiteralPath $workflowPath -Raw

Assert-True ($workflow -match "schedule:") "nightly workflow must run on a schedule"
Assert-True ($workflow -match "workflow_dispatch:") "nightly workflow must support manual dispatch"
Assert-True ($workflow -match "verify-all\.ps1") "nightly workflow must run scripts/ci/verify-all.ps1"
Assert-True ($workflow -match "IncludeMysqlSmoke") "nightly workflow must include the MySQL smoke gate"
Assert-True ($workflow -match "IncludeStorageSmoke") "nightly workflow must include the storage smoke gate"
Assert-True ($workflow -match "IncludeBrowserSmoke") "nightly workflow must include the browser smoke gate"
Assert-True ($workflow -match "IncludeBrowserE2E") "nightly workflow must include the real browser E2E gate"
Assert-True ($workflow -match "IncludeElasticsearchSmoke") "nightly workflow must include the real Elasticsearch gate"
Assert-True ($workflow -match "PLAYWRIGHT_CHANNEL: chromium") "nightly workflow must pin the Chromium Playwright channel"
Assert-True ($workflow -match "mysql:8") "nightly workflow must provision MySQL 8"
Assert-True ($workflow -match "redis:7") "nightly workflow must provision Redis 7"
Assert-True ($workflow -match "minio") "nightly workflow must provision a MinIO-compatible S3 service"
Assert-True ($workflow -match "MINIO_DEFAULT_BUCKETS") "nightly workflow must pre-create the MinIO smoke bucket"
Assert-True ($workflow -match "elasticsearch:8") "nightly workflow must provision Elasticsearch 8"

Write-Output "nightly workflow contract passed"
