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
foreach ($baseUrlName in @(
    "PLAYWRIGHT_WEB_BASE_URL",
    "PLAYWRIGHT_ADMIN_BASE_URL",
    "PLAYWRIGHT_MERCHANT_BASE_URL",
    "PLAYWRIGHT_BACKEND_BASE_URL"
)) {
    Assert-True ($playwrightConfig -match $baseUrlName) "Playwright config must support $baseUrlName"
}
Assert-True ($playwrightConfig -match "PLAYWRIGHT_REMOTE_ACCEPTANCE") "remote acceptance must disable Playwright retries"

$browserE2eScript = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($browserE2eScript -match "Start-Process") "browser E2E script must manage child processes explicitly on Windows"
Assert-True ($browserE2eScript -match "java") "browser E2E script must start the packaged backend directly"
Assert-True ($browserE2eScript -match "vite[\\/]bin[\\/]vite.js") "browser E2E script must start Vite directly through Node"
Assert-True ($browserE2eScript -match "PLAYWRIGHT_EXTERNAL_SERVERS") "browser E2E script must disable Playwright-managed server teardown"
Assert-True ($browserE2eScript -match "spring\.profiles\.active=h2,local") "real E2E backend must use the H2 and explicit local profiles"
Assert-True ($browserE2eScript -match "app\.auth\.send-code-rate-limit\.ip-window-max-requests=1000") "real E2E backend must isolate loopback IP rate-limit state across synthetic users"
Assert-True ($browserE2eScript -match "PLAYWRIGHT_OUTPUT_DIR") "browser E2E script must isolate Playwright output per run"
Assert-True ($browserE2eScript -match "ResponseHeadersRead") "browser E2E readiness probes must not block on streaming response bodies"
Assert-True ($browserE2eScript -match "PLAYWRIGHT_MERCHANT_PORT") "browser E2E must manage the merchant camera QR server"
Assert-True ($browserE2eScript -match "@playwright[\\/]test[\\/]cli.js") "browser E2E script must invoke Playwright directly without npm recursion"
Assert-True ($browserE2eScript -match "Stop-Process") "browser E2E script must stop every managed process in finally"
Assert-True ($browserE2eScript -match "Stop-BackendListener") "browser E2E script must clean a detached backend listener by verified jar path"
Assert-True ($browserE2eScript -match '\$backendProcess\s*=\s*\$null') "browser E2E script must initialize the backend process handle before try/finally"

$listenerFunctionMatch = [regex]::Match($browserE2eScript, '(?s)function Stop-BackendListener\s*\{.*?\r?\n\}')
Assert-True $listenerFunctionMatch.Success "browser E2E script must define a complete backend listener cleanup function"
$listenerFunction = $listenerFunctionMatch.Value
Assert-True ($listenerFunction -match '\[int\]\$ExpectedProcessId') "backend listener cleanup must receive the process id started by this run"
Assert-True ($listenerFunction -match '\$ownerId\s+-ne\s+\$ExpectedProcessId') "backend listener cleanup must reject listeners owned by another process"

$listenerCall = ($browserE2eScript -split "`r?`n" |
    Where-Object { $_ -match '^\s*Stop-BackendListener\s+-' } |
    Select-Object -Last 1)
Assert-True ($listenerCall -match '-ExpectedProcessId') "finally must pass the expected backend process id to listener cleanup"
Assert-True ($listenerCall -match '\$backendProcess\.Id') "finally must derive listener cleanup identity from this run backend process"

$realBackendSpec = Get-Content -LiteralPath $realBackendSpecPath -Raw
Assert-True ($realBackendSpec -match "PLAYWRIGHT_REAL_BACKEND") "real backend spec must skip unless real backend mode is enabled"
Assert-True ($realBackendSpec -match "提交点评") "real backend spec must cover review submission"
Assert-True ($realBackendSpec -match "通过点评") "real backend spec must cover admin review approval"
Assert-True ($realBackendSpec -match "渝里火锅徐汇店") "real backend spec must use H2 seed shop data"
Assert-True ($realBackendSpec -match "system/health") "real backend spec must cover admin system health"
Assert-True ($realBackendSpec -match "data/search-sync") "real backend spec must cover admin search sync operations"
Assert-True ($realBackendSpec -match "PLAYWRIGHT_REMOTE_ACCEPTANCE") "real backend spec must distinguish remote acceptance from local H2"
Assert-True ($realBackendSpec -match "PLAYWRIGHT_EXPECTED_COMMIT_SHA") "remote real backend checks must verify the expected commit"
Assert-True ($realBackendSpec -match "PLAYWRIGHT_E2E_ADMIN_ACCOUNT") "admin acceptance credentials must be configurable"
Assert-True ($realBackendSpec -match "PLAYWRIGHT_E2E_MERCHANT_ACCOUNT") "merchant acceptance credentials must be configurable"
Assert-True ($realBackendSpec -match "registerSyntheticUser") "mutable user flows must use synthetic accounts"
Assert-True ($realBackendSpec -notmatch "demo\.cn@example\.com") "real backend E2E must not mutate the shared demo user"
Assert-True ($realBackendSpec -match 'captureStream') "merchant QR E2E must decode real video frames from the issued coupon image"
Assert-True ($realBackendSpec -match 'coupon-scan-start') "merchant QR E2E must exercise the camera entry and explicit verification"
Assert-True ($realBackendSpec -match 'merchantDashboardResponse') "merchant consultation E2E must await dashboard loading before navigating away"

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
