$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts\ci\browser-e2e.ps1"
$verifyAllPath = Join-Path $repoRoot "scripts\ci\verify-all.ps1"
$webPackagePath = Join-Path $repoRoot "web\package.json"
$webPlaywrightConfigPath = Join-Path $repoRoot "web\playwright.config.ts"
$realBackendSpecPath = Join-Path $repoRoot "web\e2e\real-backend-flow.spec.ts"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $scriptPath) "scripts/ci/browser-e2e.ps1 must exist"
Assert-True (Test-Path -LiteralPath $realBackendSpecPath) "web/e2e/real-backend-flow.spec.ts must exist"

$webPackage = Get-Content -LiteralPath $webPackagePath -Raw | ConvertFrom-Json
Assert-True ($null -ne $webPackage.scripts.'test:e2e:real') "web/package.json must define scripts.test:e2e:real"
Assert-True ($webPackage.scripts.'test:e2e:real' -match "browser-e2e.ps1") "scripts.test:e2e:real must delegate managed server lifecycle to browser-e2e.ps1"

$playwrightConfig = Get-Content -LiteralPath $webPlaywrightConfigPath -Raw
Assert-True ($playwrightConfig -match "PLAYWRIGHT_REAL_BACKEND") "Playwright config must support real backend mode"
Assert-True ($playwrightConfig -match "PLAYWRIGHT_BACKEND_PORT") "Playwright config must support configurable backend port"
Assert-True ($playwrightConfig -match "VITE_PROXY_TARGET") "Playwright config must pass VITE_PROXY_TARGET to Vite dev servers"
Assert-True ($playwrightConfig -match "PLAYWRIGHT_EXTERNAL_SERVERS") "Playwright config must support externally managed E2E servers"

$browserE2eScript = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($browserE2eScript -match "Start-Process") "browser E2E script must manage child processes explicitly on Windows"
Assert-True ($browserE2eScript -match "java") "browser E2E script must start the packaged backend directly"
Assert-True ($browserE2eScript -match "vite[\\/]bin[\\/]vite.js") "browser E2E script must start Vite directly through Node"
Assert-True ($browserE2eScript -match "PLAYWRIGHT_EXTERNAL_SERVERS") "browser E2E script must disable Playwright-managed server teardown"
Assert-True ($browserE2eScript -match "spring.profiles.active=h2") "real E2E backend must use the H2 profile"
Assert-True ($browserE2eScript -match "PLAYWRIGHT_OUTPUT_DIR") "browser E2E script must isolate Playwright output per run"
Assert-True ($browserE2eScript -match "@playwright[\\/]test[\\/]cli.js") "browser E2E script must invoke Playwright directly without npm recursion"
Assert-True ($browserE2eScript -match "Stop-Process") "browser E2E script must stop every managed process in finally"

$realBackendSpec = Get-Content -LiteralPath $realBackendSpecPath -Raw
Assert-True ($realBackendSpec -match "PLAYWRIGHT_REAL_BACKEND") "real backend spec must skip unless real backend mode is enabled"
Assert-True ($realBackendSpec -match "提交点评") "real backend spec must cover review submission"
Assert-True ($realBackendSpec -match "通过点评") "real backend spec must cover admin review approval"
Assert-True ($realBackendSpec -match "渝里火锅徐汇店") "real backend spec must use H2 seed shop data"

$dryRunOutput = & $scriptPath -DryRun
$dryRunText = $dryRunOutput -join "`n"

Assert-True ($dryRunText -match "H2 backend") "dry-run output must mention H2 backend"
Assert-True ($dryRunText -match "web") "dry-run output must mention web"
Assert-True ($dryRunText -match "admin-web") "dry-run output must mention admin-web"
Assert-True ($dryRunText -match "review submission") "dry-run output must mention review submission"
Assert-True ($dryRunText -match "admin approval") "dry-run output must mention admin approval"

$verifyAll = Get-Content -LiteralPath $verifyAllPath -Raw
Assert-True ($verifyAll -match "IncludeBrowserE2E") "verify-all must expose optional full browser E2E gate"
Assert-True ($verifyAll -match "browser-e2e.ps1") "verify-all must call browser-e2e.ps1 when requested"

Write-Output "browser-e2e script contract passed"
