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
Assert-True ($workflow -match "runs-on:\s*ubuntu-24\.04") "nightly workflow must pin Ubuntu 24.04"
Assert-True (([regex]::Matches($workflow, "actions/upload-artifact@v7\.0\.2")).Count -eq 3) "nightly evidence uploads must pin upload-artifact 7.0.2"
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
Assert-True ($workflow -match 'MINIO_DEFAULT_BUCKETS:\s*["'']?dzdp-smoke:download["'']?') "nightly workflow must allow anonymous downloads from the MinIO smoke bucket"
Assert-True ($workflow -match "elasticsearch:8") "nightly workflow must provision Elasticsearch 8"
Assert-True ($workflow -match "merchant-web/package-lock\.json") "nightly workflow must cache merchant-web dependencies"
Assert-True ($workflow -match "npm ci --prefix merchant-web") "nightly workflow must install merchant-web dependencies"

$creatorStep = [regex]::Match($workflow, '(?ms)^      - name: Verify creator review browser flow\r?\n(?:(?!^      - ).)*').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($creatorStep)) "nightly must run the creator workflow separately from closed-launch regression"
Assert-True ($creatorStep -match 'run: npx playwright test e2e/creator-review\.spec\.ts') "nightly creator step must select only the creator browser scenarios"
Assert-True ($creatorStep -match 'PLAYWRIGHT_REAL_BACKEND: "1"' -and $creatorStep -match 'PLAYWRIGHT_CREATOR_REVIEW: "1"') "nightly creator step must use a real test backend"
Assert-True ($creatorStep -match 'APP_STATE_STORE_KEY_PREFIX: dzdp:nightly:creator') "nightly creator step must isolate its state store"
foreach ($flag in @('APP_LAUNCH_DEFERRED_FEATURES_ENABLED', 'APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED')) {
    Assert-True ($creatorStep -match "(?m)^          ${flag}: `"true`"\s*$") "nightly creator test flags must be scoped to this step"
    Assert-True ([regex]::Matches($workflow, "${flag}:").Count -eq 1) "creator flags must not leak into the ordinary nightly regression"
}
Assert-True ($creatorStep -notmatch 'continue-on-error') "creator browser failures must fail nightly regression"
Assert-True ($workflow -match 'path: web/test-results/creator-review/') "nightly must preserve creator browser evidence"

$seckillStep = [regex]::Match($workflow, '(?ms)^      - name: Verify flash-sale orders on MySQL\r?\n(?:(?!^      - ).)*').Value
Assert-True ($seckillStep -match 'seckill-order-integration\.py --server docker') "nightly must verify flash-sale transactions and browsers on disposable MySQL"
Assert-True ($seckillStep -notmatch 'continue-on-error') "flash-sale failures must fail nightly regression"
Assert-True ($workflow -match 'path: reports/seckill-order-integration/') "nightly must preserve flash-sale evidence"

Write-Output "nightly workflow contract passed"
