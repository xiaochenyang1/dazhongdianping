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

Assert-True ($workflow -match '(?ms)push:\s*branches:\s*- main\s*tags:\s*- "eu-pre-rc-\*"') "workflow must limit push verification to main and release-candidate tags"
Assert-True ($workflow -match '(?ms)pull_request:\s*branches:\s*- main') "workflow must verify pull requests targeting main"
Assert-True ($workflow -match '(?ms)concurrency:\s*group:\s*ci-\$\{\{ github\.workflow \}\}-\$\{\{ github\.event\.pull_request\.number \|\| github\.ref \}\}\s*cancel-in-progress:\s*true') "workflow must cancel superseded CI runs per branch or pull request"
Assert-True (([regex]::Matches($workflow, "runs-on:\s*ubuntu-24\.04")).Count -eq 2) "all CI jobs must pin Ubuntu 24.04"
Assert-True (([regex]::Matches($workflow, "actions/upload-artifact@v7\.0\.2")).Count -eq 3) "CI evidence uploads must pin upload-artifact 7.0.2"

Assert-True ($workflow -match "verify-all\.ps1") "workflow must run scripts/ci/verify-all.ps1"
Assert-True ($workflow -match "IncludeMysqlSmoke") "workflow must include the MySQL smoke gate"
Assert-True ($workflow -match "IncludeStorageSmoke") "workflow must include the storage smoke gate"
Assert-True ($workflow -match "IncludeBrowserSmoke") "workflow must include the browser smoke gate"
Assert-True ($workflow -match "IncludeBrowserE2E") "workflow must run real backend browser flows before merge"
Assert-True ($workflow -match "playwright install --with-deps chromium") "workflow must install Playwright Chromium for browser smoke"
Assert-True ($workflow -match "PLAYWRIGHT_CHANNEL: chromium") "workflow must run browser smoke with the Chromium channel"
Assert-True ($workflow -match "mysql:8") "workflow must provision MySQL 8"
Assert-True ($workflow -match "redis:7") "workflow must provision Redis 7"
Assert-True ($workflow -match "minio") "workflow must provision a MinIO-compatible S3 service"
Assert-True ($workflow -match "MINIO_DEFAULT_BUCKETS") "workflow must pre-create the MinIO smoke bucket"
Assert-True ($workflow -match 'MINIO_DEFAULT_BUCKETS:\s*["'']?dzdp-smoke:download["'']?') "workflow must allow anonymous downloads from the MinIO smoke bucket"
Assert-True ($workflow -match "APP_DB_PASSWORD") "workflow must pass MySQL credentials through environment variables"
Assert-True ($workflow -match "APP_STATE_STORE_PROVIDER: redis") "workflow must run backend smoke with Redis state store"
Assert-True ($workflow -match "APP_S3_ENDPOINT") "workflow must provide the S3 endpoint for storage smoke"
Assert-True ($workflow -match "subosito/flutter-action") "workflow must install Flutter"
Assert-True ($workflow -match 'flutter-version:\s*"3\.44\.8"') "workflow must pin Flutter 3.44.8"
Assert-True ($workflow -match "IncludeFlutter") "workflow must include the Flutter verification gate"
Assert-True ($workflow -match 'docker compose -f deploy/smoke-services[.]compose[.]yml config --quiet') "workflow must validate the local smoke service composition"
Assert-True ($workflow -match "merchant-web/package-lock\.json") "workflow must cache merchant-web dependencies"
Assert-True ($workflow -match "npm ci --prefix merchant-web") "workflow must install merchant-web dependencies"

$migrationJobMatch = [regex]::Match(
    $workflow,
    '(?ms)^  database-migration-integration:\r?\n(?:(?!^  [A-Za-z0-9_-]+:).)*'
)
Assert-True $migrationJobMatch.Success "workflow must define a separate database-migration-integration job"
$migrationJob = $migrationJobMatch.Value
Assert-True ($migrationJob -match "runs-on:\s*ubuntu-24\.04") "migration integration job must run on Ubuntu 24.04"
Assert-True ($migrationJob -match "timeout-minutes:\s*10") "migration integration job must have a bounded timeout"
Assert-True ($migrationJob -match "contents:\s*read") "migration integration job must use read-only repository permissions"
Assert-True ($migrationJob -match "MYSQL_MIGRATION_TEST_IMAGE:\s*mysql:8\.4") "migration integration job must pin the tested MySQL release"
Assert-True ($migrationJob -match "apt-get install -y mysql-client") "migration integration job must install the MySQL client"
Assert-True ($migrationJob -match "chmod \+x scripts/ci/mysql-migrate\.sh scripts/ci/test-mysql-migration-integration\.sh") "migration integration job must make both migration scripts executable"
Assert-True ($migrationJob -match "run:\s*\./scripts/ci/test-mysql-migration-integration\.sh") "migration integration job must run the real MySQL migration suite"
Assert-True ($migrationJob -notmatch "continue-on-error") "migration integration failures must block CI"

$creatorStep = [regex]::Match($workflow, '(?ms)^      - name: Verify creator review browser flow\r?\n(?:(?!^      - ).)*').Value
Assert-True (-not [string]::IsNullOrWhiteSpace($creatorStep)) "CI must run the creator workflow separately from closed-launch regression"
Assert-True ($creatorStep -match 'run: npx playwright test e2e/creator-review\.spec\.ts') "creator CI must run only the creator browser scenarios"
Assert-True ($creatorStep -match 'PLAYWRIGHT_REAL_BACKEND: "1"' -and $creatorStep -match 'PLAYWRIGHT_CREATOR_REVIEW: "1"') "creator CI must use a real feature-enabled test backend"
Assert-True ($creatorStep -match 'APP_STATE_STORE_KEY_PREFIX: dzdp:ci:creator') "creator CI must isolate verification-code and idempotency state"
foreach ($flag in @('APP_LAUNCH_DEFERRED_FEATURES_ENABLED', 'APP_LAUNCH_EU_CREATOR_REWARDS_ENABLED')) {
    Assert-True ($creatorStep -match "(?m)^          ${flag}: `"true`"\s*$") "creator test flags must be scoped to this step"
    Assert-True ([regex]::Matches($workflow, "${flag}:").Count -eq 1) "creator flags must not leak into other CI steps"
}
Assert-True ($creatorStep -notmatch 'continue-on-error') "creator browser failures must block CI"
Assert-True ($workflow -match 'path: web/test-results/creator-review/') "CI must preserve creator screenshots and failure traces"

Write-Output "ci workflow contract passed"
