$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\browser-smoke.ps1"
$webPackagePath = Join-Path $repoRoot "web\package.json"
$webPlaywrightConfigPath = Join-Path $repoRoot "web\playwright.config.ts"
$webSmokeSpecPath = Join-Path $repoRoot "web\e2e\browser-smoke.spec.ts"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/browser-smoke.ps1 must exist"
Assert-True (Test-Path -LiteralPath $webPlaywrightConfigPath) "web/playwright.config.ts must exist"
Assert-True (Test-Path -LiteralPath $webSmokeSpecPath) "web/e2e/browser-smoke.spec.ts must exist"

$webPackage = Get-Content -LiteralPath $webPackagePath -Raw | ConvertFrom-Json
Assert-True ($null -ne $webPackage.scripts.'test:e2e') "web/package.json must define scripts.test:e2e"
Assert-True ($webPackage.scripts.'test:e2e' -match "browser-smoke\.ps1") "scripts.test:e2e must delegate to browser-smoke.ps1"
Assert-True ($null -ne $webPackage.devDependencies.'@playwright/test') "web/package.json must include @playwright/test"

$dryRunOutput = & $scriptPath -DryRun
$dryRunText = $dryRunOutput -join "`n"

Assert-True ($dryRunText -match "browser-smoke\.spec\.ts") "dry-run output must mention browser-smoke.spec.ts"
Assert-True ($dryRunText -match "Start web Vite directly with Node") "dry-run output must mention direct web startup"
Assert-True ($dryRunText -match "Chromium") "dry-run output must mention Chromium"
Assert-True ($dryRunText -match "web") "dry-run output must mention web smoke"
Assert-True ($dryRunText -match "admin-web") "dry-run output must mention admin-web smoke"
Assert-True ($dryRunText -match "/shops/1/reviews/new") "dry-run output must mention guarded review route"
Assert-True ($dryRunText -match "/login") "dry-run output must mention admin login route"

Write-Output "browser-smoke script contract passed"
