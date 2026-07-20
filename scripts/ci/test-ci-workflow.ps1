$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowPath = Join-Path $repoRoot ".github\workflows\ci.yml"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $workflowPath) ".github/workflows/ci.yml must exist"

$workflow = Get-Content -LiteralPath $workflowPath -Raw

Assert-True ($workflow -match "verify-all\.ps1") "workflow must run scripts/ci/verify-all.ps1"
Assert-True ($workflow -match "IncludeMysqlSmoke") "workflow must include the MySQL smoke gate"
Assert-True ($workflow -match "IncludeStorageSmoke") "workflow must include the storage smoke gate"
Assert-True ($workflow -match "IncludeBrowserSmoke") "workflow must include the browser smoke gate"
Assert-True ($workflow -match "playwright install --with-deps chromium") "workflow must install Playwright Chromium for browser smoke"
Assert-True ($workflow -match "PLAYWRIGHT_CHANNEL: chromium") "workflow must run browser smoke with the Chromium channel"
Assert-True ($workflow -match "mysql:8") "workflow must provision MySQL 8"
Assert-True ($workflow -match "redis:7") "workflow must provision Redis 7"
Assert-True ($workflow -match "minio") "workflow must provision a MinIO-compatible S3 service"
Assert-True ($workflow -match "MINIO_DEFAULT_BUCKETS") "workflow must pre-create the MinIO smoke bucket"
Assert-True ($workflow -match "APP_DB_PASSWORD") "workflow must pass MySQL credentials through environment variables"
Assert-True ($workflow -match "APP_STATE_STORE_PROVIDER: redis") "workflow must run backend smoke with Redis state store"
Assert-True ($workflow -match "APP_S3_ENDPOINT") "workflow must provide the S3 endpoint for storage smoke"
Assert-True ($workflow -match "subosito/flutter-action") "workflow must install Flutter"
Assert-True ($workflow -match "IncludeFlutter") "workflow must include the Flutter verification gate"
Assert-True ($workflow -match "merchant-web/package-lock\.json") "workflow must cache merchant-web dependencies"
Assert-True ($workflow -match "npm ci --prefix merchant-web") "workflow must install merchant-web dependencies"

Write-Output "ci workflow contract passed"
